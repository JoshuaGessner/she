class_name NetPlan
extends Object

## How this process intends to connect, decided before a session exists.
##
## `CoopSession` used to read `--host` / `--join` off the command line itself,
## which worked for probes and CI and gave a menu nowhere to put an answer.
## This is that answer: **one place the intent lives**, written by the command
## line *or* by the main menu, read by the session and by nothing else.
##
## Not an autoload. `TEC-001` budgets six and names which six, and a seventh
## would have to displace one of them; static state on a `class_name` costs no
## budget and is reachable from the menu and the session alike.
##
## ## What this is not
##
## **It is not matchmaking, and it does not solve NAT.** There is no relay
## here, no hole-punching, and no lobby server — this is a **direct
## connection**, and a join code is only a shorter way to write an address. An
## address reaches a host whose port is actually reachable: the same network,
## or `DEFAULT_PORT` forwarded to that machine. `M4-T07` brings Steam's relay.
##
## Saying so plainly matters: a system that looked like matchmaking and quietly
## failed for anyone behind a router would waste a tester's evening and read as
## a netcode bug. The host screen says it too, where somebody will actually see
## it.
##
## ## Why this shape survives `M4-T07`
##
## Steam changes **where an address comes from** — a lobby, an invite, a relay
## handle — and changes nothing about what the session does with it. So the
## session asks this class for a role and a destination and stays exactly as it
## is; `M4-T07` adds a way to *fill this in*, and direct entry stops being the
## only way rather than becoming the fallback nobody maintains (ADR-064).

enum Role { SOLO, HOST, CLIENT }

## The project's port, and **the only place it is written down**. `CoopSession`
## carried its own copy and this file was introduced with a different number —
## two constants with the same name and different values, which is the drift
## this project keeps catching in other people's honest mistakes and had just
## made in its own.
const DEFAULT_PORT: int = 47018

## Crockford-style: no I, L, O or U, so a code read aloud over voice chat or
## copied off a screenshot cannot become a different code. Case-insensitive on
## the way back in.
const ALPHABET: String = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

static var role: Role = Role.SOLO
static var address: String = "127.0.0.1"
static var port: int = DEFAULT_PORT

## Set when a join fails, so the menu can say why rather than silently doing
## nothing — the single most common way a connection screen wastes an evening.
static var last_error: String = ""


## Read the command line into the plan. Called by `CoopSession` before it looks
## at anything else, so probes and CI keep working unchanged and there is still
## only one place the intent lives.
static func adopt_cmdline(args: PackedStringArray) -> void:
	for arg: String in args:
		if arg == "--host":
			role = Role.HOST
		elif arg.begins_with("--join"):
			role = Role.CLIENT
			if arg.contains("="):
				address = arg.split("=", true, 1)[1]
		elif arg.begins_with("--port="):
			port = int(arg.split("=", true, 1)[1])


## A short shareable code for an address, or the address itself when it is not
## a plain IPv4 (a hostname or a DNS name, which is more useful to a tester
## than anything this could encode).
static func code_for(host: String, at_port: int) -> String:
	var octets: PackedStringArray = host.split(".")
	if octets.size() != 4:
		return "%s:%d" % [host, at_port]
	var value: int = 0
	for octet: String in octets:
		var part: int = int(octet)
		if part < 0 or part > 255:
			return "%s:%d" % [host, at_port]
		value = (value << 8) | part
	value = (value << 16) | (at_port & 0xFFFF)
	# 48 bits, ten base-32 digits, most significant first.
	var out: String = ""
	for digit: int in range(10):
		var shift: int = (9 - digit) * 5
		out += ALPHABET[(value >> shift) & 0x1F]
	return out


## Parse whatever somebody pasted into the join field: a code, `host:port`, or
## a bare host. One parser rather than three input modes — the formats differ,
## the destination does not.
static func adopt_code(typed: String) -> bool:
	var text: String = typed.strip_edges()
	if text.is_empty():
		last_error = "nothing to join"
		return false

	if text.length() == 10 and not text.contains(":") and not text.contains("."):
		var value: int = 0
		for letter: String in text.to_upper():
			var digit: int = ALPHABET.find(letter)
			if digit < 0:
				last_error = "'%s' is not part of a join code" % letter
				return false
			value = (value << 5) | digit
		port = value & 0xFFFF
		address = "%d.%d.%d.%d" % [
			(value >> 40) & 0xFF, (value >> 32) & 0xFF,
			(value >> 24) & 0xFF, (value >> 16) & 0xFF]
		last_error = ""
		return true

	var host: String = text
	var wanted: int = DEFAULT_PORT
	if text.contains(":"):
		var halves: PackedStringArray = text.rsplit(":", true, 1)
		host = halves[0]
		wanted = int(halves[1]) if halves[1].is_valid_int() else DEFAULT_PORT
	# Rejected rather than accepted-and-ignored. A join that silently goes
	# nowhere is indistinguishable from broken netcode, and the player has no
	# way to tell that what they typed was never an address at all.
	if not _plausible_host(host):
		last_error = "'%s' is not an address or a join code" % text
		return false
	address = host
	port = wanted
	last_error = ""
	return true


## Whether this could be a hostname or an IPv4 literal. Deliberately permissive
## about *which* host — resolution and reachability are the transport's problem
## — and strict only about characters no address ever contains.
static func _plausible_host(host: String) -> bool:
	if host.is_empty() or host.length() > 253:
		return false
	for letter: String in host:
		var alphanumeric: bool = (letter >= "a" and letter <= "z") \
			or (letter >= "A" and letter <= "Z") \
			or (letter >= "0" and letter <= "9")
		if not alphanumeric and not ".-_".contains(letter):
			return false
	return true


## The best guess at an address a second machine could reach, for the host to
## read out. Loopback is filtered because handing somebody `127.0.0.1` is
## handing them their own machine.
static func local_address() -> String:
	for candidate: String in IP.get_local_addresses():
		if candidate.begins_with("127.") or candidate.contains(":"):
			continue
		if candidate.begins_with("169.254."):
			continue
		return candidate
	return "127.0.0.1"
