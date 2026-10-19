// mapspawn_combiner/modules/laser_pointer/module_laser_pointer.nut
// DRG-style laser pointer: an engine-rendered beam from your marine to your
// crosshair, visible to every player — other clients need NO files. The beam
// stops on enemies and teammates, not just walls. Firing while the pointer is
// active "marks" the target: a glow flash at the spot. Optional chat line with
// name and distance is off by default (mark_chat).
//
// Activation:
//   chat:    laser  (or !laser)                 — toggle
//   console: scripted_user_func laser           — toggle without chat spam (bindable)
//            scripted_user_func laser_on / laser_off — for hold-style +/- aliases
//
// Tunables: !am_vars / !am_set / !am_disable / !am_enable (admin module).
// Mutating commands need the mapspawn_combiner/admins.nut / McAuth whitelist.
//
// Rendering (all engine-side, no client scripts):
//   beam — persistent server-side env_beam between two tracked marker entities
//   mark — env_sprite glow flash

if ( "LaserPointerLoaded" in getroottable() ) {
    ::McLog.Info( "[MC] laser_pointer: already loaded, skip" );
} else {
    getroottable().LaserPointerLoaded <- true;

local m = {
    name        = "laser_pointer",
    enabled     = true,
    convars     = {},
    version     = "1.0.10",
    description = "DRG-style laser pointer: a beam everyone sees. Check your console for key binding examples.",

    // Printed to the player's console by !am_info (chat is too narrow for binds).
    // Mirrors the Controls section of the README.
    console_info = [
        "=== laser_pointer controls ===",
        "Toggle in chat:       say  laser   (or !laser)",
        "Silent toggle bind:   bind v \"scripted_user_func laser\"",
        "Hold mode (beam shines while the key is held):",
        "  alias +lp \"scripted_user_func laser_on\"",
        "  alias -lp \"scripted_user_func laser_off\"",
        "  bind MOUSE4 \"+lp\"",
        "Mark without firing:  bind MOUSE5 \"scripted_user_func laser_mark\"",
        "Full DRG gesture (hold = beam, release = mark, no shot):",
        "  alias +lpm \"scripted_user_func laser_on\"",
        "  alias -lpm \"scripted_user_func laser_mark; scripted_user_func laser_off\"",
        "  bind MOUSE4 \"+lpm\"",
        "Mark by firing too:   !am_set laser_pointer mark_on_fire 1",
    ],
    requires_registry = 4,

    // variables, their defaults and the help texts shown by !am_vars are
    // declared in ONE list via ::McRegistry.DeclareVariables below the table literal.

    // activation tokens (chat + scripted_user_func)
    _TOK_TOGGLE = "laser",
    _TOK_ON     = "laser_on",
    _TOK_OFF    = "laser_off",
    _TOK_MARK   = "laser_mark",   // mark without firing; in a -release alias put it BEFORE laser_off

    _PREFIX = "[LP] ",

    // Chat tip on join (как !tkc_help / !am_help)
    _TIP_DELAY   = 3.5,
    _TIP_TEXT    = "laser pointer — say laser (or !laser); binds: !am_info laser_pointer",
    _pendingTips = null,
    _tipped      = null,

    // Engine assets, always shipped with the game (see asw_ammo.cpp / asw_tesla_trap.cpp)
    _MARKER_MODEL = "models/swarm/ammo/ammoassaultrifle.mdl",
    _FLASH_SPRITE = "sprites/glow01.vmt",
    // End glow from the particle list (electrical_fx.pcf). Clients draw it
    // only when rd_info_particle_system_enabled is 1.
    _TIP_EFFECT   = "blink",

    _COLORS = ["255 50 50", "0 220 255", "50 255 50", "255 220 0",
               "255 140 0", "255 50 255", "220 220 220", "160 50 255"],

    _players    = {},               // hPlayer -> state table (see _newState)
    _slotOwner  = array(8, null),   // slot -> hPlayer; keeps per-player colors stable
    _nextUpdate = 0.0,
    _trace      = {},               // reusable table for ScriptTraceLineTable (no per-tick allocs)
    _VEC_ZERO   = Vector(0, 0, 0),  // mins = maxs = zero => line trace

    // ---------- messaging ----------

    function _msg(hPlayer, text) {
        ClientPrint(hPlayer, HudPrint.Talk, this._PREFIX + text);
    },

    function _broadcast(text) {
        ClientPrint(null, HudPrint.Talk, this._PREFIX + text);
    },

    function _noSlots(hPlayer) {
        this._msg(hPlayer, "No free laser slots.");
    },

    function _sendHelpTip(hPlayer) {
        if (hPlayer == null || !hPlayer.IsValid())
            return;
        local id = ::McAuth.PlayerKey(hPlayer);
        if (id != null) {
            if (this._tipped == null)
                this._tipped = {};
            if (id in this._tipped)
                return;
            this._tipped[id] <- true;
        }
        this._msg(hPlayer, this._TIP_TEXT);
    },

    function _flushHelpTips() {
        if (this._pendingTips == null || this._pendingTips.len() == 0)
            return;
        local now = Time();
        local remaining = [];
        foreach (entry in this._pendingTips) {
            if (now >= entry.showAt)
                this._sendHelpTip(entry.player);
            else
                remaining.append(entry);
        }
        this._pendingTips = remaining;
    },

    // ---------- per-player state ----------

    // rd_hud_vscript as a beam endpoint marker: FL_EDICT_ALWAYS (networked to
    // every client; a modelless info_target is not — that sank an early
    // version), plus an invisible model: an entity WITH a model is not a
    // "static point" (beam_shared.cpp IsStaticPointEntity), so the persistent
    // env_beam tracks its position client-side every frame.
    function _marker(targetname) {
        local e = Entities.CreateByClassname("rd_hud_vscript");
        e.__KeyValueFromString("targetname", targetname);
        e.__KeyValueFromInt("rendermode", 10);   // kRenderNone — the model is never drawn
        e.__KeyValueFromInt("effects", 272);     // EF_NOSHADOW | EF_NORECEIVESHADOW
        e.Spawn();
        e.Activate();
        e.SetModel(this._MARKER_MODEL);
        return e;
    },

    function _newState(hPlayer, slot) {
        local u = UniqueString();
        local srcName = "lp_src_" + slot + u;
        local dstName = "lp_dst_" + slot + u;

        local src = this._marker(srcName);
        local dst = this._marker(dstName);

        // Engine-rendered mark flash. Named + no StartOn spawnflag = spawns
        // hidden (Sprite.cpp); ShowSprite/HideSprite toggle it.
        local flash = Entities.CreateByClassname("env_sprite");
        flash.__KeyValueFromString("targetname", "lp_flash_" + slot + u);
        flash.__KeyValueFromString("model", this._FLASH_SPRITE);
        flash.__KeyValueFromString("rendercolor", this._COLORS[slot]);
        flash.__KeyValueFromInt("renderamt", 255);
        flash.__KeyValueFromInt("rendermode", 9);    // world-space glow
        flash.__KeyValueFromFloat("scale", 0.4);
        flash.Spawn();
        flash.Activate();

        return {
            slot = slot, active = false,
            src = src, dst = dst, flash = flash, tip = null,
            beam = null, beamOn = false,
            tipStarted = -999.0,
            srcName = srcName, dstName = dstName,
            lastMark = -999.0, lastEnd = null, lastHit = null,
            lastActive = Time(),
            lastBeamRefresh = 0.0,
        };
    },

    // Markers always required. Beam may be null until first _ensureBeam while
    // active; if it existed and died, force a full rebuild.
    function _entsValid(st) {
        if (st.src == null || !st.src.IsValid()) return false;
        if (st.dst == null || !st.dst.IsValid()) return false;
        if (st.flash == null || !st.flash.IsValid()) return false;
        if (st.beam != null && !st.beam.IsValid()) return false;
        return true;
    },

    function _getState(hPlayer) {
        if (hPlayer in this._players) {
            local st = this._players[hPlayer];
            if (this._entsValid(st))
                return st;
            // entities gone (mission restart or idle cleanup) — rebuild, keep
            // the slot (stable color) and the active flag
            return this._rebuildState(hPlayer, st);
        }
        local slot = -1;
        for (local i = 0; i < this._slotOwner.len(); i++) {
            local owner = this._slotOwner[i];
            if (owner == null || !owner.IsValid()) { slot = i; break; }
        }
        if (slot < 0) return null;
        this._slotOwner[slot] = hPlayer;
        local st = this._newState(hPlayer, slot);
        this._players[hPlayer] <- st;
        return st;
    },

    function _rebuildState(hPlayer, stOld) {
        this._destroyState(stOld);
        local st = this._newState(hPlayer, stOld.slot);
        st.active = stOld.active;
        this._slotOwner[stOld.slot] = hPlayer;
        this._players[hPlayer] <- st;
        return st;
    },

    function _destroyState(st) {
        foreach (k in ["tip", "src", "dst", "flash", "beam"]) {
            if (st[k] != null && st[k].IsValid()) st[k].Destroy();
            st[k] = null;
        }
        st.beamOn = false;
        local owner = this._slotOwner[st.slot];
        if (owner == null || !owner.IsValid()) this._slotOwner[st.slot] = null;
    },

    // ---------- env_beam ----------

    // Persistent server-side env_beam (life = 0). Both endpoints are entities
    // WITH models, so every client tracks the marker positions.
    // TurnOn/TurnOff only toggle EF_NODRAW; the endpoint binding is kept.
    //
    // env_beam is PVS-culled. For BEAM_ENTPOINT the server treats the beam
    // origin as the start of that box. A beam left at the map origin drops
    // out of everyone's PVS once the segment crosses more than two areas:
    // the shaft vanishes and only the red end (where the line still clips
    // into the room) remains. Parent once to the source marker, which is
    // FL_EDICT_ALWAYS and already moves with the marine. Snap the beam onto
    // that marker first so the local origin stays 0 — do not SetOrigin the
    // beam again after that.
    function _ensureBeam(st) {
        if (st.beam != null && st.beam.IsValid()) return st.beam;
        local b = Entities.CreateByClassname("env_beam");
        b.__KeyValueFromString("targetname", "lp_beam_" + st.slot + UniqueString());
        b.__KeyValueFromString("LightningStart", st.srcName);
        b.__KeyValueFromString("LightningEnd", st.dstName);
        b.__KeyValueFromString("texture", "sprites/laserbeam.vmt");
        b.__KeyValueFromString("life", "0");                 // permanent, server-side
        b.__KeyValueFromFloat("BoltWidth", this.variables.beam_width.tofloat());
        b.__KeyValueFromString("rendercolor", this._COLORS[st.slot]);
        b.__KeyValueFromInt("renderamt", this.variables.beam_alpha.tointeger());
        b.__KeyValueFromFloat("NoiseAmplitude", 0.0);
        b.__KeyValueFromInt("TextureScroll", 0);
        b.__KeyValueFromString("spawnflags", "1");           // StartOn
        b.Spawn();
        b.Activate();    // binds the (modeled => tracked) endpoint entities here
        b.SetOrigin(st.src.GetOrigin());
        b.SetParent(st.src);
        if (b.GetMoveParent() == null)
            ::McLog.Warn( "[LP] beam transmit parent failed (slot " + st.slot + ")" );
        st.beam = b;
        st.beamOn = true;
        st.lastBeamRefresh = Time();
        return b;
    },

    function _refreshBeam(st) {
        if (st.beam != null && st.beam.IsValid())
            st.beam.Destroy();
        st.beam = null;
        st.beamOn = false;
        this._ensureBeam(st);
    },

    function _beamOff(st) {
        if (st.beam != null && st.beam.IsValid() && st.beamOn)
            DoEntFire("!self", "TurnOff", "", 0, null, st.beam);
        st.beamOn = false;
        this._tipOff(st);
    },

    function _tipOff(st) {
        if (st.tip != null && st.tip.IsValid())
            st.tip.Destroy();
        st.tip = null;
    },

    // info_particle_system is sent to every client. start_active must be set
    // before Spawn, or Activate never turns the system on. Do not parent it.
    function _placeTip(st, pos) {
        local now = Time();
        if (st.tip != null && st.tip.IsValid() && (now - st.tipStarted) < 0.45) {
            st.tip.SetOrigin(pos);
            return;
        }
        this._tipOff(st);
        local p = Entities.CreateByClassname("info_particle_system");
        p.__KeyValueFromString("effect_name", this._TIP_EFFECT);
        p.__KeyValueFromString("start_active", "1");
        p.SetOrigin(pos);
        p.Spawn();
        p.Activate();
        st.tip = p;
        st.tipStarted = now;
    },

    // Fire an entity input on every existing beam — makes beam_width/beam_alpha
    // changes visible immediately (creation keyvalues only cover new beams).
    function _applyBeamInput(szInput, value) {
        foreach (hPlayer, st in this._players) {
            if (st.beam != null && st.beam.IsValid())
                DoEntFire("!self", szInput, "" + value, 0, null, st.beam);
        }
    },

    // ---------- activation ----------

    function _setActive(hPlayer, on, announce) {
        ::McThinkers.EnsureUpdateThinker();
        local st = this._getState(hPlayer);
        if (st == null) { this._noSlots(hPlayer); return; }
        if (st.active == on) return;
        st.active = on;
        if (on) st.lastActive = Time();
        else this._beamOff(st);
        if (announce)
            this._broadcast(hPlayer.GetPlayerName() + ": laser " + (on ? "ON" : "OFF"));
    },

    function _toggle(hPlayer, announce) {
        local st = this._getState(hPlayer);
        if (st == null) { this._noSlots(hPlayer); return; }
        this._setActive(hPlayer, !st.active, announce);
    },

    // ---------- hooks ----------

    function OnGameplayStart() {
        // Soft rebuild: new marker/beam entities, keep who had laser ON.
        this.Cleanup();
        PrecacheModel(this._MARKER_MODEL);
        PrecacheModel(this._FLASH_SPRITE);
        PrecacheParticleSystem(this._TIP_EFFECT);
    },

    // admin calls this on !am_disable: hide everything we own. Active
    // flags are kept, so !am_enable resumes the lasers on the next Update.
    function OnDisable() {
        foreach (hPlayer, st in this._players)
            this._beamOff(st);
    },

    // !am_set validation: null = accept, false = reject, else corrected value.
    // beam_width/beam_alpha are additionally pushed to the existing beams via
    // CBeam inputs ("Width", base "Alpha"), so the change applies instantly.
    function OnVariableChanged(name, value) {
        if (name == "interval" && value < 0.02) return 0.02;
        if (name == "idle_ttl" && value < 0)    return 0;
        if (name == "beam_width") {
            local w = (value < 0.1) ? 0.1 : value;
            this._applyBeamInput("Width", w);
            return (w == value) ? null : w;
        }
        if (name == "beam_alpha") {
            local a = value;
            if (a < 0)   a = 0;
            if (a > 255) a = 255;
            this._applyBeamInput("Alpha", a.tointeger());
            return (a == value) ? null : a;
        }
    },

    function OnGameEvent_player_activate(params) {
        if (!("userid" in params)) return;
        local hPlayer = GetPlayerFromUserID(params["userid"]);
        if (hPlayer == null || !hPlayer.IsValid()) return;

        if (this._tipped == null)
            this._tipped = {};
        if (this._pendingTips == null)
            this._pendingTips = [];

        local id = ::McAuth.PlayerKey(hPlayer);
        if (id != null && (id in this._tipped))
            return;
        foreach (entry in this._pendingTips) {
            if (entry.player == hPlayer)
                return;
        }
        this._pendingTips.append({ player = hPlayer, showAt = Time() + this._TIP_DELAY });
    },

    function OnGameEvent_player_say(params) {
        if (!("text" in params)) return;
        local t = params["text"].tolower();
        if (t != this._TOK_TOGGLE && t != "!" + this._TOK_TOGGLE) return;
        local hPlayer = GetPlayerFromUserID(params["userid"]);
        if (hPlayer == null || !hPlayer.IsValid()) return;
        this._toggle(hPlayer, true);
    },

    // From the dispatcher: scripted_user_func <token> lands here (and so does
    // menuselect, which the engine forwards too) — match tokens exactly.
    // params = { player = hPlayer, value = szValue }
    function UserConsoleCommand(params) {
        local hPlayer = params.player;
        if (hPlayer == null || !hPlayer.IsValid()) return;
        local v = params.value.tolower();
        if      (v == this._TOK_TOGGLE) this._toggle(hPlayer, true);
        else if (v == this._TOK_ON)     this._setActive(hPlayer, true, false);
        else if (v == this._TOK_OFF)    this._setActive(hPlayer, false, false);
        else if (v == this._TOK_MARK)   this._tryMark(hPlayer);
    },

    function OnGameEvent_weapon_fire(params) {
        if (this.variables.mark_on_fire == 0) return;
        if (!("userid" in params)) return;
        local hPlayer = GetPlayerFromUserID(params["userid"]);
        if (hPlayer == null || !hPlayer.IsValid()) return;

        // only shots from the marine this player controls
        local hMarine = hPlayer.GetMarine();
        if (hMarine == null || !hMarine.IsValid()) return;
        if (("marine" in params) && params["marine"] != hMarine.entindex()) return;

        this._tryMark(hPlayer);
    },

    // ---------- mark ----------

    // Shared by the weapon_fire path and the laser_mark token: requires an
    // active pointer and a living marine, rate-limited by mark_cooldown.
    function _tryMark(hPlayer) {
        if (!(hPlayer in this._players)) return;
        local st = this._players[hPlayer];
        if (!st.active || st.flash == null || !st.flash.IsValid()) return;

        local hMarine = hPlayer.GetMarine();
        if (hMarine == null || !hMarine.IsValid()) return;

        if (Time() - st.lastMark < this.variables.mark_cooldown) return;
        st.lastMark = Time();
        this._doMark(hPlayer, hMarine, st);
    },

    function _doMark(hPlayer, hMarine, st) {
        local pos = (st.lastEnd != null) ? st.lastEnd : hPlayer.GetCrosshairTracePos();

        // engine-rendered glow flash — everyone sees it, no client files needed
        st.flash.SetOrigin(pos);
        DoEntFire("!self", "ShowSprite", "", 0, null, st.flash);
        DoEntFire("!self", "HideSprite", "", this.variables.mark_duration.tofloat(), null, st.flash);

        if (this.variables.mark_chat != 0) {
            // the beam trace already told us what we are pointing at
            local what;
            if (st.lastHit != null && st.lastHit.IsValid()) what = this._describeEntity(st.lastHit);
            else what = this._describeTarget(pos);

            local d = pos - hMarine.GetOrigin();
            local dist = sqrt(d.x * d.x + d.y * d.y + d.z * d.z).tointeger();
            this._broadcast(hPlayer.GetPlayerName() + " marks " + what + " (" + dist + " units)");
        }

        if (this.variables.mark_particles != 0) this._particleBurst(pos);
    },

    function _describeEntity(e) {
        if (e.GetClassname() == "asw_marine") return e.GetMarineName();
        return e.GetClassname();
    },

    // Fallback for when the ray hit the world: name the nearest notable entity
    // around the endpoint (corpses, items and other non-solid things the trace
    // cannot hit).
    function _describeTarget(pos) {
        local radius = this.variables.mark_radius.tofloat();
        local best = null;
        local bestDistSq = radius * radius;
        local e = null;
        while ((e = Entities.FindInSphere(e, pos, radius)) != null) {
            if (!e.IsValid()) continue;
            local cls = e.GetClassname();
            if (cls == "rd_hud_vscript" || cls == "env_beam" || cls == "player"
                || cls == "worldspawn"
                || cls.find("info_") == 0 || cls.find("trigger_") == 0
                || cls.find("func_") == 0 || cls.find("env_") == 0) continue;
            local dd = e.GetOrigin() - pos;
            local distSq = dd.x * dd.x + dd.y * dd.y + dd.z * dd.z;
            if (distSq < bestDistSq) { best = e; bestDistSq = distSq; }
        }
        if (best == null) return "a position";
        return this._describeEntity(best);
    },

    // Legacy world-space burst. Off by default.
    function _particleBurst(pos) {
        foreach (eff in [this._TIP_EFFECT, "explosion_sparks"]) {
            local p = Entities.CreateByClassname("info_particle_system");
            p.__KeyValueFromString("effect_name", eff);
            p.__KeyValueFromString("start_active", "1");
            p.SetOrigin(pos);
            p.Spawn();
            p.Activate();
            DoEntFire("!self", "Kill", "", 2.0, null, p);
        }
    },

    // ---------- update loop ----------

    function Update() {
        this._flushHelpTips();

        if (Time() < this._nextUpdate) return;
        this._nextUpdate = Time() + this.variables.interval;

        local toRemove = [];
        local toHeal = [];

        foreach (hPlayer, st in this._players) {
            if (!hPlayer.IsValid()) { toRemove.append(hPlayer); continue; }

            if (!st.active) {
                // free this player's edicts after idle_ttl seconds; the slot and
                // the entry stay, so the color survives reactivation
                if (st.src != null && this.variables.idle_ttl > 0
                    && Time() - st.lastActive > this.variables.idle_ttl)
                    this._destroyState(st);
                continue;
            }
            st.lastActive = Time();

            if (!this._entsValid(st)) {
                toHeal.append(hPlayer);
                continue;
            }

            local hMarine = hPlayer.GetMarine();
            if (hMarine == null || !hMarine.IsValid()) {
                this._beamOff(st);        // hidden while dead; auto-resumes on respawn
                continue;
            }

            local srcPos = hMarine.GetOrigin() + Vector(0, 0, this.variables.src_height.tofloat());
            local dstPos = hPlayer.GetCrosshairTracePos();

            // Clip against world AND characters (default mask is
            // MASK_VISIBLE_AND_NPCS): the beam stops on aliens and marines like
            // the DRG pointer, and the hit entity names the mark target.
            local t = this._trace;
            t.ignore <- hMarine;
            ScriptTraceLineTable(t, srcPos, dstPos, this._VEC_ZERO, this._VEC_ZERO);
            dstPos = t.pos;
            local hit = t.enthit;
            st.lastHit = (hit != null && hit.IsValid() && hit.GetClassname() != "worldspawn") ? hit : null;
            st.lastEnd = dstPos;

            local tipPos = dstPos;
            if ("normal" in t)
                tipPos = dstPos + t.normal * 8;

            st.src.SetOrigin(srcPos);
            st.dst.SetOrigin(dstPos);

            local refresh = this.variables.beam_refresh.tofloat();
            if (refresh > 0 && (Time() - st.lastBeamRefresh) >= refresh)
                this._refreshBeam(st);

            local b = this._ensureBeam(st);
            if (!st.beamOn) {
                DoEntFire("!self", "TurnOn", "", 0, null, b);
                st.beamOn = true;
            }
            this._placeTip(st, tipPos);
        }

        foreach (p in toHeal) {
            ::McLog.Info( "[LP] rebuilding entities (slot "
                + this._players[p].slot + ")" );
            this._rebuildState(p, this._players[p]);
        }
        foreach (p in toRemove) {
            this._destroyState(this._players[p]);
            this._players.rawdelete(p);
        }
    },

    // Soft reset: drop old edicts, keep slot + active. Next Update recreates
    // the beam for anyone who still has active=true. Hard wipe of _players
    // (old behavior) made lasers stay off until a manual toggle after missions.
    function Cleanup() {
        local kept = [];
        foreach (hPlayer, st in this._players) {
            if (hPlayer == null || !hPlayer.IsValid())
                continue;
            kept.append({
                player = hPlayer,
                slot   = st.slot,
                active = st.active,
            });
            this._destroyState(st);
        }
        this._players = {};
        this._slotOwner = array(8, null);
        this._nextUpdate = 0.0;

        local nActive = 0;
        foreach (e in kept) {
            this._slotOwner[e.slot] = e.player;
            local st = this._newState(e.player, e.slot);
            st.active = e.active;
            this._players[e.player] <- st;
            if (e.active)
                nActive++;
        }
        if (kept.len() > 0)
            ::McLog.Info( "[LP] Cleanup: soft-rebuild " + kept.len()
                + " player(s), " + nActive + " laser(s) still ON" );
    },
};

// Single source for every tunable: name, default, help (printed by !am_vars).
// Optional 4th element = GUI widget metadata (unused by combiner yet):
//   {min,max,step} -> slider,  {kind="bool"} -> toggle,  omitted -> [-]/[+] stepper.
::McRegistry.DeclareVariables(m, [
    ["interval",       0.05, "update period, seconds",                              { min = 0.01, max = 0.5, step = 0.01 }],
    ["src_height",     45,   "beam source height (45 = weapon, 60 = head)",         { min = 20,   max = 80,  step = 5 }],
    ["mark_radius",    64,   "fallback target search radius at the endpoint",       { min = 16,   max = 256, step = 8 }],
    ["mark_cooldown",  1.0,  "minimum seconds between marks",                        { min = 0,    max = 5,   step = 0.1 }],
    ["mark_duration",  1.2,  "mark flash duration, seconds",                        { min = 0.2,  max = 5,   step = 0.1 }],
    ["mark_chat",      0,    "1 = announce ping target and distance in chat",       { kind = "bool" }],
    ["mark_particles", 0,    "1 = extra particle burst on mark (map-dependent)",    { kind = "bool" }],
    ["mark_on_fire",   0,    "1 = firing while active also marks",                  { kind = "bool" }],
    ["idle_ttl",       60,   "free an idle player's entities after N sec (0 = keep)", { min = 0,  max = 300, step = 10 }],
    ["beam_refresh",   0,    "recreate env_beam every N sec while on (0 = off)",    { min = 0,    max = 60,  step = 1 }],
    ["beam_width",     1.5,  "beam width, applies to existing beams instantly",     { min = 0.5,  max = 8,   step = 0.5 }],
    ["beam_alpha",     220,  "beam opacity 0-255, applies instantly",               { min = 0,    max = 255, step = 5 }],
]);

::McRegistry.Register(m);

} // LaserPointerLoaded