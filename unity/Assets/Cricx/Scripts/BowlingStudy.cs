using UnityEngine;

namespace Cricx {
    // Baked Blender bone curves and root travel; no capsule player or runtime limb posing.
    public sealed class BowlingStudy : MonoBehaviour {
        public GameObject athlete;
        public AnimationClip deliveryClip;
        public Transform bowlingHand;
        public Transform pelvis;
        public Rigidbody ball;
        public StudyCamera studyCamera;
        public float releaseTime = 2.4f;
        public float actionDuration = 3.5f;
        [Range(60, 100)] public float speedKmh = 75;
        public Vector3 bounceTarget = new Vector3(0, .076f, 15.5f);
        float time;
        bool bowling, released;
        Vector3 ballOrigin;
        public bool IsBowling => bowling;

        void Start() {
            Time.fixedDeltaTime = 1f / 120f;
            ResetStudy();
        }
        public void ResetStudy() {
            bowling = released = false; time = 0;
            ball.isKinematic = true; ball.useGravity = false;
            if (deliveryClip && athlete) deliveryClip.SampleAnimation(athlete, 0);
            CarryBall();
        }
        public void Bowl() {
            if (bowling || !deliveryClip || !bowlingHand) return;
            ResetStudy(); bowling = true;
        }
        void Update() {
            if (!bowling) { CarryBall(); return; }
            float previous = time;
            time += Time.deltaTime;
            // Evaluate the exact release frame even when a rendered frame crosses it.
            if (!released && previous <= releaseTime && time >= releaseTime) {
                deliveryClip.SampleAnimation(athlete, releaseTime);
                CarryBall(); Launch();
            }
            deliveryClip.SampleAnimation(athlete, Mathf.Min(time, actionDuration));
            if (!released) CarryBall();
            if (time >= actionDuration + 3f) ResetStudy();
        }
        void CarryBall() {
            if (bowlingHand) ball.transform.position = bowlingHand.position;
        }
        void Launch() {
            released = true; ballOrigin = ball.position;
            Vector3 velocity;
            if (!TryLaunchVelocity(ballOrigin, bounceTarget, speedKmh / 3.6f, out velocity)) {
                Debug.LogError("Bounce target is unreachable at this speed.");
                ResetStudy(); return;
            }
            ball.isKinematic = false; ball.useGravity = true;
            ball.linearVelocity = velocity;
            ball.angularVelocity = new Vector3(-32, 0, 85);
        }
        public static bool TryLaunchVelocity(Vector3 origin, Vector3 target, float speed, out Vector3 velocity) {
            Vector3 offset = target - origin;
            Vector3 flat = new Vector3(offset.x, 0, offset.z);
            float distance = flat.magnitude, g = -Physics.gravity.y;
            float s2 = speed * speed;
            float discriminant = s2 * s2 - g * (g * distance * distance + 2 * offset.y * s2);
            velocity = Vector3.zero;
            if (distance < .001f || discriminant < 0 || g <= 0) return false;
            float angle = Mathf.Atan((s2 - Mathf.Sqrt(discriminant)) / (g * distance));
            velocity = flat.normalized * (speed * Mathf.Cos(angle)) + Vector3.up * (speed * Mathf.Sin(angle));
            return true;
        }
        // This milestone presents the bowler and camera. UI is intentionally limited to review controls.
        void OnGUI() {
            float scale = Mathf.Min(Screen.width / 1280f, Screen.height / 720f);
            Matrix4x4 old = GUI.matrix;
            GUI.matrix = Matrix4x4.TRS(Vector3.zero, Quaternion.identity, Vector3.one * scale);
            GUI.Box(new Rect(18, 18, 420, 52), "CRICX · BOWLING NETS");
            GUI.enabled = !bowling;
            if (GUI.Button(new Rect(1070, 584, 180, 68), "BOWL")) Bowl();
            GUI.enabled = true;
            if (GUI.Button(new Rect(18, 628, 140, 52), "CAMERA")) studyCamera.Cycle();
            if (GUI.Button(new Rect(174, 628, 140, 52), "RESET")) ResetStudy();
            GUI.Label(new Rect(470, 650, 540, 40), bowling ? (released ? "RELEASE → FOLLOW THROUGH" : "RUN-UP → GATHER → FRONT-FOOT PLANT") : "RIGHT-ARM FINGER-SPIN · READY");
            GUI.matrix = old;
        }
    }
}
