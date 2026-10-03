# Off-spin reference study

**Historical planning:** the character/action implementation described below was removed from the current 0.4.0 nets-only rebuild. It remains in earlier Git commits. Delivery research is still provisional.

## Evidence and limits

The user supplied **Harbhajan Singh Bowling Style Analysis.mp4**, 10.854 seconds, 720 × 1280 at 30 fps, plus a portrait. The footage contains edits, slow motion, a side-angle excerpt, a rear view of one delivery, and a closer approach view. It is useful for an animation study, not calibrated motion capture. The supplied video and portrait are not redistributed in this repository.

Online verification was attempted against ICC, ESPNcricinfo, Wikipedia and a search engine on 2026-10-03. All requests were blocked with HTTP 403, including a retried biography fetch. Consequently this is **a video analysis and provisional technical brief, not completed source-verified deep research**. The descriptions below use general cricket knowledge; they do not establish every delivery Harbhajan used, when he used it, or its frequency. No measured spin rates, speeds, joint angles or release heights are inferred from this footage.

## What the footage supports

- A compact approach and upward gather, with both hands raised near/above the head.
- A hop/gather and delivery stride: the rear leg folds while the front leg extends toward its landing.
- The non-bowling arm leads before drawing down; the bowling arm comes over high.
- Torso rotation and lateral lean accompany release; the body continues forward into recovery.

The grip, finger pressure and seam rotation are not sufficiently resolved to identify this particular ball as an off-break, doosra or another variation. Apparent straightness of an arm in a perspective image is not a biomechanical legality measurement.

The implemented keyframes are manually authored estimates. Their timing is chosen for a game animation, not copied from the slowed/edited video. They use a placeholder articulated character with reference-inspired headwear and beard, not a face scan, textured realistic human, or exact likeness.

## Provisional repertoire assessment

### Off-break — primary delivery

Harbhajan is known as a right-arm off-spin bowler. An off-break's characteristic lateral turn is from the off side toward the leg side of a right-handed batter; that direction generally takes it away from a left-handed batter. Finger-generated rotation, release axis, seam presentation, pitch grip and speed affect how much it turns. An off-break can also carry topspin and produce dip and bounce.

Game requirement: a controllable three-dimensional spin vector, a consistent release, and surface-dependent lateral deviation on impact. Do not rotate a ball's trajectory by an arbitrary angle at a preselected pitch marker. The game must use actual ground contact.

### Doosra — major career association

Harbhajan is widely associated with the doosra: an off-spinner's variation that turns in the opposite direction to the stock off-break. It generally moves away from a right-handed batter and toward a left-handed batter. It is not simply a renamed leg-spinner's googly. A similar large-scale action helps disguise the delivery, but grip, wrist/forearm orientation and release differ. Those changes cannot be recovered accurately from this clip.

Game requirement: opposite effective lateral spin at bounce, with a dedicated hand/wrist pose that can be refined against close-up evidence. A rotated label on the same no-spin ball is not a doosra. Bowling legality must not be inferred from visual elbow bend alone; testing concerns elbow extension during a specified part of the delivery.

### Topspinner — technical candidate requiring player-specific verification

Forward rotation can produce extra dip and a different bounce, with less sideways turn when the spin axis is predominantly transverse to travel. Actual bounce height also depends on incoming vertical velocity, restitution, surface friction and speed; topspin must not guarantee an exaggerated high bounce.

A top-spinning component and a separately named topspinner are different claims. Obtain reliable player-specific analysis before presenting this as a distinct, documented Harbhajan selection in the game.

### Straighter / quicker ball — behaviour is not proof of a named variation

Off-spinners can vary pace, seam and spin so a ball turns less and arrives differently. "Quicker," "flatter," "arm ball," "slider" and "straight one" should not automatically be treated as interchangeable. A stock ball can also fail to turn because of the pitch.

Game requirement: independent pace, elevation, spin amount and seam state. A distinct arm-ball slot for Harbhajan requires corroborating sources or close-up footage. Swing, if implemented, must use a separate aerodynamic/seam model rather than substituting spin turn.

### Flight, drift, dip, line, length and crease position

These describe controllable properties or effects, not five additional named deliveries. Flight concerns trajectory and time in the air; drift is lateral air movement; dip is extra downward curvature; bounce and turn occur at ground contact. Release speed, elevation and spin can be varied within the same delivery family.

Do not add carrom ball, flipper, slider, googly or a claimed exhaustive set of tricks merely because another spinner bowls them. Harbhajan-specific evidence is needed for each attribution.

## Physics plan

The current prototype has gravity, restitution and rolling friction, but **no angular velocity, aerodynamic spin force or spin-dependent bounce**. The new action study does not change that fact.

A subsequent spin implementation should:

1. Store angular velocity in radians/second, separate from linear velocity in metres/second.
2. Integrate flight with gravity, drag and a calibrated spin-dependent aerodynamic force. A Magnus-style direction comes from the cross product of spin and relative air velocity; coefficients require validation, not guessed celebrity measurements.
3. Resolve the ball's velocity at the surface contact point, including the contribution of rotation. Apply a tangential impulse bounded by friction and the normal impulse, updating both linear and angular velocity. The spin-axis direction matters; reversing an arbitrary screen-space offset does not model an opposite-turning ball.
4. Keep seam and pitch variability explicit. Line and length controls must preserve incoming delivery geometry and avoid teleporting the ball onto a target.
5. Animate seam orientation from angular velocity so the visible rotation agrees with simulation.

Required checks include mirror tests for opposite lateral spin, timestep stability, zero-spin baseline, surface friction sensitivity, conservation/dissipation checks, bounce ordering and reproducible landing dispersion. Realism then requires reference trajectories with known scale and timing.

## Implementation and review

`OffspinAction` defines approach, gather, delivery stride, front-foot plant, release, follow-through and recovery. A torso pivot coordinates shoulders, head and arms. Arm and leg solvers preserve segment lengths. The front shoe stays in one world position from front-foot plant through release. The ball launches from the animated bowling hand; its initial lateral velocity aims at the requested wicket line. The bowler's travel stays beside the stumps.

Tests cover fixed arm lengths, foot height, two-hand bat grip, release linkage, planted front shoe, a near-straight release arm and release lean. These are implementation constraints, not evidence of motion-capture accuracy or similarity to Harbhajan.

`tools/bowling_review.gd` renders 180 frames covering side/front views. Review both views against the supplied footage before considering this animation finished. The action study is now included in APK 0.3.0 along with straight-ball bowling nets. Off-break/doosra spin physics remains unimplemented.

## External verification still needed

- A reputable career profile confirming the stock action and documented doosra use, with publication dates.
- Contemporary technical analysis or interviews distinguishing topspin, straight/quick balls and any named arm-ball use.
- Full-speed, uninterrupted side and front/rear delivery footage, plus grip/release close-ups for each claimed variation.
- Measurements or trustworthy tracking data before specifying physical ranges as Harbhajan's own.

Useful verification starting points, **not sources accessed successfully in this session**:

- [ESPNcricinfo player profile](https://www.espncricinfo.com/cricketers/harbhajan-singh-29264)
- [ICC](https://www.icc-cricket.com/)
- [Harbhajan Singh biography and its bibliography](https://en.wikipedia.org/wiki/Harbhajan_Singh)
