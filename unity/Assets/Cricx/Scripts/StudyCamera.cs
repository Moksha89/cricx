using UnityEngine;
namespace Cricx {
    public sealed class StudyCamera : MonoBehaviour {
        public Transform pelvis;
        public Rigidbody ball;
        public BowlingStudy study;
        int view;
        Vector3 dampVelocity;
        public void Cycle() { view = (view + 1) % 3; }
        void LateUpdate() {
            if (!pelvis) return;
            Vector3 anchor = pelvis.position;
            Vector3 eye, look;
            if (view == 1) { eye = new Vector3(6, 2.5f, 1); look = anchor + Vector3.up * .3f; }
            else if (view == 2) { eye = new Vector3(.4f, 2.6f, -10.5f); look = new Vector3(0, 1, 7); }
            else {
                eye = anchor + new Vector3(-.5f, 1.45f, -4.6f);
                look = anchor + new Vector3(0, .1f, .35f);
                if (!ball.isKinematic) {
                    // Follow the ball only after launch; keep the athlete visible through release.
                    Vector3 destination = ball.position + new Vector3(.25f, 1.65f, -4.5f);
                    eye = Vector3.Lerp(eye, destination, Mathf.Clamp01((ball.position.z - anchor.z - 2) / 8));
                    look = Vector3.Lerp(look, ball.position + Vector3.forward, Mathf.Clamp01((ball.position.z - anchor.z - 2) / 8));
                }
            }
            if (view == 0) { eye.y = Mathf.Min(eye.y, 2.9f); eye.x = Mathf.Clamp(eye.x, -2.2f, 2.2f); eye.z = Mathf.Min(eye.z, 22.5f); }
            transform.position = Vector3.SmoothDamp(transform.position, eye, ref dampVelocity, .12f);
            Quaternion desired = Quaternion.LookRotation(look - transform.position, Vector3.up);
            transform.rotation = Quaternion.Slerp(transform.rotation, desired, 1 - Mathf.Exp(-12 * Time.deltaTime));
        }
    }
}
