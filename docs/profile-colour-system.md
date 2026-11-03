---
status: current
version: 1.0
---

# Profile pages: colour system and frosted controls

How the client and provider profile pages are coloured, and why. Read this
before adding a row, card or button to either page so the colours keep their
meaning.

Code: [lib/widgets/profile_kit.dart](../lib/widgets/profile_kit.dart) (palette
and building blocks), [lib/widgets/frosted_icon_button.dart](../lib/widgets/frosted_icon_button.dart)
(frosted controls), [lib/screens/profile_screen.dart](../lib/screens/profile_screen.dart)
(client), [lib/screens/provider/profile/profile_tab.dart](../lib/screens/provider/profile/profile_tab.dart)
(provider).

## 1. The principle: one brand colour, four meaning colours

Brand blue is the only colour that says "this is Sahulat Ghar Tak". It never
changes between the client and the provider side, so a user who switches
accounts sees the same identity. Everything else is neutral, plus a small set
of supporting hues that each carry **one meaning**.

Target proportions (the 60-30-10 rule):

| Share | Role | What fills it |
|---|---|---|
| ~60% | Brand | Header gradient, primary buttons, switches, links |
| ~30% | Neutral | Page tint, white cards, ink text, grey labels |
| ~10% | Accent | The four supporting hues below, used only in small chips, icon badges and tints |

If a screen feels rainbow, the accents are over 10%. Remove colour, don't add it.

## 2. Brand colours (unchanged by the profile work)

| Token | Hex | Where |
|---|---|---|
| Brand blue | `#016EE3` | Primary actions, selected states, verified tick, client and provider headers |
| Brand dark | `#0A4FA8` | Left end of header gradients, card shadow tint |
| Brand accent | `#4FC3F7` | Light highlight (landing Register button) |
| Indigo (`kPrimaryColor`) | `#6366F1` | Auth screens and the request form's default accent only. Not used on profile pages. |

Constants: `providerBrandBlue` / `providerBrandDark` (provider side) and the
private `_brandBlue` / `_brandDark` in `profile_screen.dart`. They hold the same
values on purpose. The header gradient is `[dark, blue]` on both pages.

## 3. Supporting hues (the 10%)

Defined once in `profile_kit.dart` as `kProfileTeal`, `kProfileViolet`,
`kProfileAmber`, `kProfileCoral`. Mid saturation, so they sit calmly beside
`#016EE3` instead of competing with it.

| Hue | Hex | Meaning | Used for |
|---|---|---|---|
| Teal | `#0E9F8E` | Contact, trust, location | Mobile, city, "Jobs done", My Documents, "Pinned on map" / "Pin on map" |
| Violet | `#7C5CFC` | Identity and skills | Gender, CNIC, Experience, Categories, Office/Work address |
| Amber | `#F59E0B` | Work and rating | Rating star, category rows, "other" address labels |
| Coral | `#F2685B` | Time | Available timing, Member since, the 24-hour switch icon |

Status colours are separate from these and must not be reused as decoration:

| Colour | Meaning |
|---|---|
| Green (`Colors.green`) | Online, success |
| Orange (`Colors.orange`) | Warning, "Verification pending" banner |
| Red | Destructive only (Delete Account, delete address) |

Why these meanings: a user scanning the page should be able to tell a contact
detail from an identity detail without reading. Pairing each hue with one
category also keeps the page learnable. When a new row appears, pick the hue
by what it *is*, not by what looks nice.

### How a hue is applied

Never as a solid fill. Always as a tint of one hue:

- Icon badge: hue at 10-13% alpha behind a full-strength icon.
- Chip or tile fill: hue at 9-12% alpha, border at 22-35% alpha.
- Text in that hue only for short labels ("Pinned on map"), never body copy.

Body text stays ink `#14213D`, labels stay black at 45-55% alpha.

## 4. Neutrals and surfaces

| Token | Value | Role |
|---|---|---|
| `kProfileBody` | `#F1F5FB` | Page background behind the cards (cool grey-blue, picks up the brand hue) |
| Card | white, radius 18, shadow `#0A4FA8` at 6% | Raised surface |
| Ink | `#14213D` | Titles and values |
| Slate | `#64748B` | The "Account details" (IDs) drawer: deliberately neutral so admin data doesn't compete with content |

The body tint is passed through the optional `bodyColor` on
`CurvedProfileHeader` (white by default, so other screens are unaffected).
White cards on a white page only separate by shadow; the tint makes them read
as raised.

## 5. Frosted-glass controls

Used for controls that sit on a **gradient or photo**, where a bare white icon
gets lost. Specification (identical everywhere):

- Backdrop blur sigma 10
- Fill: white at 20% alpha (tinted for status, e.g. green at 35% for Online)
- 1 px rim: white at 40% alpha
- Icon/text: white

Widgets: `FrostedIconButton` (circle), `FrostedBackButton` (back arrow, pops by
default), `FrostedSurface` (pill or rounded button).

Where it is used: header back arrows, notification bell, logout, Rejected
history button, "Mark all read", the provider Online pill, the landing Login
button, the camera back arrow, and the remove-photo ×.

**Rule: only use it over a gradient or image.** On a white card a translucent
white button is invisible. Buttons on white surfaces use the brand-blue
outlined or filled styles (`kProminentOutlinedButtonStyle`,
`kProminentFilledButtonStyle`).

## 6. Hierarchy of actions on the profile pages

1. One filled brand-blue action per page: **Switch to Customer / Provider**
   (or Become a Provider).
2. Outlined brand blue for secondary actions (Edit Profile, Contact Us).
3. Tinted quick-action tiles for navigation shortcuts, each in its section hue.
4. Plain text for low-priority or risky actions: Privacy Policy, and Delete
   Account in red. Delete is a small text button on purpose; it is destructive
   and rare, and it still asks for the password.

## 7. IDs are hidden

User ID, Provider ID, Category ID and Account type live in a collapsed
**Account details** drawer (`ProfileIdsDrawer`). Tapping a row copies it. The
CNIC is masked as `42101-*******-3` until the eye icon is tapped
(`ProfileSecretRow`, `maskCnic`).

## 8. Adding to the pages: checklist

- New detail row: pick the hue by meaning (table in section 3) and use
  `ProfileDetailRow`. If none fits, use brand blue, not a fifth hue.
- New hue? Don't, unless a new *meaning* appears that none of the four cover.
  If it does, add a constant to `profile_kit.dart` and a row to the table
  above.
- Status needs green/orange/red, not a supporting hue.
- Don't use indigo `#6366F1` here; it belongs to the auth flow.
- Check the colour is still readable at small sizes (labels at 12 px) and does
  not carry meaning on its own: every coloured row also has an icon and a
  text label.
- Motion: the staggered entrance (`staggerProfile`) and shimmer skeleton
  (`ProfileSkeleton`) are skipped when the OS reduce-motion setting is on.
