# Rev 0.6 test checklist

## Build / sign-in
- [ ] Android APK builds in GitHub Actions.
- [ ] Web artifact builds in GitHub Actions.
- [ ] Existing owner account signs in and existing dogs/history remain.

## Firestore upgrade
- [ ] Publish the included `firestore.rules` in **Cloud Firestore → Rules**.
- [ ] Do not replace the working Realtime Database rules.

## Admin
- [ ] Club Admin appears for Owner/Admin.
- [ ] Import/create/edit/archive/restore Teams.
- [ ] Default fault types can be created; add/rename/reorder/disable/restore works.
- [ ] Other fault accepts free text.
- [ ] Owner can change member roles.

## Competitions
- [ ] Existing competition opens.
- [ ] Edit competition works.
- [ ] Move test competition to Bin.
- [ ] Restore works.
- [ ] Permanent delete requires confirmation and removes linked races/legs/dog-run copies.

## Reports
- [ ] All-club report loads.
- [ ] Filter by one/set of competitions.
- [ ] Filter by team / organisation / Blue or Red lane.
- [ ] Speed, W-L-D, clean %, faults, reruns and dog KPIs make sense against known test data.
- [ ] Blank times do not become zero.
- [ ] Sponsor PDF can be saved/shared.
- [ ] Sponsor summary and CSV can be copied.

## Live Ring accessibility
- [ ] Sound toggle works.
- [ ] Haptics toggle works independently of sound.
- [ ] Three red cues give short haptic feedback; green is stronger.
- [ ] Fault-light repeat ON/OFF behaviour from 0.5.4 remains working.

## Centre Display / Viewer
- [ ] Auto display follows window/device orientation.
- [ ] Force Portrait works.
- [ ] Force Landscape works.
- [ ] Blue/Red controllers stay landscape.
- [ ] Phone ↔ web live sync still works.

## Camera Beta (hosted web Main Display)
- [ ] Browser asks for camera permission.
- [ ] Two connected webcams can be selected independently.
- [ ] Both live previews show.
- [ ] Start-line overlay can be moved on both lanes.
- [ ] A zero capture is attempted for both cameras.
- [ ] Camera errors are shown rather than breaking the ring display.
