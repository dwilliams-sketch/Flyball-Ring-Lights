FLYBALL RING LIGHTS — REV 0.1.2

Tiny layout safety fix for phones that still showed a 2–3 pixel bottom overflow.

Changes:
- Blue and Red lane columns now have a final FittedBox(scaleDown) safety net.
- Centre light stack also scales down if Android gives the app a few fewer pixels.
- Timer keeps its own reserved area above GO / STOP / RESET.
- Vertical padding reduced slightly.
- No timing, sound or fault behaviour changed.

Upload the CONTENTS of this patch to the existing GitHub repository:
- lib
- pubspec.yaml
- REV_0_1_2_README.txt

Commit:
Fix final landscape overflow
