from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

import matplotlib.pyplot as plt
import numpy as np


from mcap.reader import make_reader
from mcap_ros2.decoder import DecoderFactory

DEFAULT_TOPIC_SUFFIX = "/hardware/cartesian_trajectory_controller/cartesian_trajectory_telemetry"


@dataclass
class TelemetrySample:
    t: float
    ref_pos: np.ndarray
    act_pos: np.ndarray
    ref_lin: np.ndarray
    act_lin: np.ndarray
    ref_ang: np.ndarray
    act_ang: np.ndarray
    cmd_lin: np.ndarray
    cmd_ang: np.ndarray
    orient_err_rad: float
    ref_force: np.ndarray
    act_force: np.ndarray


def _vec3(obj: dict[str, Any], key: str) -> np.ndarray:
    return np.array([obj[key]["x"], obj[key]["y"], obj[key]["z"]], dtype=float)


def _quat(obj: dict[str, Any]) -> np.ndarray:
    o = obj["orientation"]
    return np.array([o["x"], o["y"], o["z"], o["w"]], dtype=float)


def _wrench_force(wrench: dict[str, Any]) -> np.ndarray:
    return np.array(wrench.get("force", [0.0, 0.0, 0.0]), dtype=float)


def _stamp_to_sec(header: dict[str, Any]) -> float:
    stamp = header["stamp"]
    return float(stamp["sec"]) + float(stamp["nanosec"]) * 1e-9


def _quat_angle_error(q_ref: np.ndarray, q_act: np.ndarray) -> float:
    q_ref = q_ref / np.linalg.norm(q_ref)
    q_act = q_act / np.linalg.norm(q_act)
    dot = float(np.clip(abs(np.dot(q_ref, q_act)), -1.0, 1.0))
    return 2.0 * np.arccos(dot)


def _parse_telemetry(payload: str, fallback_t: float) -> TelemetrySample | None:
    try:
        msg = json.loads(payload)
    except json.JSONDecodeError:
        return None

    ref_pose = msg["reference_pose"]
    act_pose = msg["actual_pose"]
    ref_twist = msg["reference_twist"]
    act_twist = msg["actual_twist"]
    cmd_twist = msg.get("commanded_twist", ref_twist)

    t = _stamp_to_sec(msg["header"]) if "header" in msg else fallback_t

    ref_wrench = msg.get("reference_wrench", {})
    act_wrench = msg.get("actual_wrench", {})

    return TelemetrySample(
        t=t,
        ref_pos=_vec3(ref_pose, "position"),
        act_pos=_vec3(act_pose, "position"),
        ref_lin=_vec3(ref_twist, "linear"),
        act_lin=_vec3(act_twist, "linear"),
        ref_ang=_vec3(ref_twist, "angular"),
        act_ang=_vec3(act_twist, "angular"),
        cmd_lin=_vec3(cmd_twist, "linear"),
        cmd_ang=_vec3(cmd_twist, "angular"),
        orient_err_rad=_quat_angle_error(_quat(ref_pose), _quat(act_pose)),
        ref_force=_wrench_force(ref_wrench),
        act_force=_wrench_force(act_wrench),
    )


def _resolve_topic(requested: str | None, available: Iterable[str]) -> str:
    topics = list(available)
    if requested:
        if requested not in topics:
            raise SystemExit(
                f"Topic '{requested}' not found in bag.\n"
                f"Available topics:\n  " + "\n  ".join(sorted(topics))
            )
        return requested

    matches = [t for t in topics if t.endswith(DEFAULT_TOPIC_SUFFIX) or DEFAULT_TOPIC_SUFFIX in t]
    if len(matches) == 1:
        return matches[0]
    if len(matches) > 1:
        raise SystemExit(
            "Multiple telemetry topics found; pass --topic explicitly:\n  "
            + "\n  ".join(sorted(matches))
        )

    string_topics = [t for t in topics if "telemetry" in t.lower()]
    if len(string_topics) == 1:
        return string_topics[0]

    raise SystemExit(
        "Could not auto-detect telemetry topic. Pass --topic.\n"
        f"Available topics:\n  " + "\n  ".join(sorted(topics))
    )


def load_samples(mcap_path: Path, topic: str | None) -> tuple[str, list[TelemetrySample]]:
    samples: list[TelemetrySample] = []
    seen_topics: set[str] = set()

    with mcap_path.open("rb") as stream:
        reader = make_reader(stream, decoder_factories=[DecoderFactory()])
        for _schema, channel, _message, ros_msg in reader.iter_decoded_messages():
            seen_topics.add(channel.topic)
            if topic is None:
                continue
            if channel.topic != topic:
                continue
            fallback_t = _message.log_time * 1e-9
            sample = _parse_telemetry(ros_msg.data, fallback_t)
            if sample is not None:
                samples.append(sample)

    if topic is None:
        topic = _resolve_topic(None, seen_topics)
        return load_samples(mcap_path, topic)

    if not samples:
        raise SystemExit(f"No valid telemetry messages on topic '{topic}'.")

    # Re-base time to start at zero for nicer axis labels.
    t0 = samples[0].t
    for s in samples:
        s.t -= t0

    return topic, samples


def _style_axis(ax: plt.Axes, title: str, ylabel: str) -> None:
    ax.set_title(title, fontsize=11, fontweight="semibold")
    ax.set_xlabel("time [s]")
    ax.set_ylabel(ylabel)
    ax.grid(True, alpha=0.3)
    ax.legend(loc="upper right", fontsize=8)


def plot_samples(samples: list[TelemetrySample], topic: str, save: Path | None, show: bool) -> None:
    t = np.array([s.t for s in samples])

    ref_pos = np.vstack([s.ref_pos for s in samples])
    act_pos = np.vstack([s.act_pos for s in samples])
    ref_lin = np.vstack([s.ref_lin for s in samples])
    act_lin = np.vstack([s.act_lin for s in samples])
    ref_ang = np.vstack([s.ref_ang for s in samples])
    act_ang = np.vstack([s.act_ang for s in samples])
    cmd_lin = np.vstack([s.cmd_lin for s in samples])
    orient_err = np.degrees(np.array([s.orient_err_rad for s in samples]))
    pos_err = np.linalg.norm(ref_pos - act_pos, axis=1)

    ref_force = np.vstack([s.ref_force for s in samples])
    act_force = np.vstack([s.act_force for s in samples])
    has_wrench = np.any(np.abs(ref_force) > 1e-12) or np.any(np.abs(act_force) > 1e-12)

    try:
        plt.style.use("seaborn-v0_8-whitegrid")
    except OSError:
        plt.style.use("ggplot")
    fig = plt.figure(figsize=(14, 10), constrained_layout=True)
    fig.suptitle(f"Cartesian trajectory telemetry\n{topic}", fontsize=13, fontweight="bold")

    axes_labels = [("x", 0), ("y", 1), ("z", 2)]
    colors_ref = "#2563eb"
    colors_act = "#dc2626"
    colors_cmd = "#16a34a"

    # Position
    for row, (label, idx) in enumerate(axes_labels):
        ax = fig.add_subplot(4, 3, row + 1)
        ax.plot(t, ref_pos[:, idx], color=colors_ref, lw=1.5, label="reference")
        ax.plot(t, act_pos[:, idx], color=colors_act, lw=1.2, alpha=0.9, label="actual")
        _style_axis(ax, f"position {label}", "position [m]")

    # Position error norm
    ax_err = fig.add_subplot(4, 3, 4)
    ax_err.plot(t, pos_err * 1000.0, color="#7c3aed", lw=1.5)
    _style_axis(ax_err, "position error", "error [mm]")
    ax_err.legend().remove()

    # Orientation error
    ax_ori = fig.add_subplot(4, 3, 5)
    ax_ori.plot(t, orient_err, color="#ea580c", lw=1.5)
    _style_axis(ax_ori, "orientation error", "error [deg]")
    ax_ori.legend().remove()

    # 3D path
    ax3d = fig.add_subplot(4, 3, 6, projection="3d")
    ax3d.plot(ref_pos[:, 0], ref_pos[:, 1], ref_pos[:, 2], color=colors_ref, lw=1.5, label="reference")
    ax3d.plot(act_pos[:, 0], act_pos[:, 1], act_pos[:, 2], color=colors_act, lw=1.2, alpha=0.9, label="actual")
    ax3d.set_title("Cartesian path", fontsize=11, fontweight="semibold")
    ax3d.set_xlabel("x [m]")
    ax3d.set_ylabel("y [m]")
    ax3d.set_zlabel("z [m]")
    ax3d.legend(loc="upper right", fontsize=8)

    # Linear velocity
    for col, (label, idx) in enumerate(axes_labels):
        ax = fig.add_subplot(4, 3, 7 + col)
        ax.plot(t, ref_lin[:, idx], color=colors_ref, lw=1.5, label="reference")
        ax.plot(t, act_lin[:, idx], color=colors_act, lw=1.2, alpha=0.9, label="actual")
        ax.plot(t, cmd_lin[:, idx], color=colors_cmd, lw=1.0, ls="--", alpha=0.8, label="commanded")
        _style_axis(ax, f"linear velocity {label}", "velocity [m/s]")

    # Angular velocity (reuse bottom row if no wrench, else add figure)
    if has_wrench:
        fig2, axs2 = plt.subplots(2, 3, figsize=(14, 6), constrained_layout=True)
        fig2.suptitle(f"Angular velocity & wrench\n{topic}", fontsize=13, fontweight="bold")
        for col, (label, idx) in enumerate(axes_labels):
            ax = axs2[0, col]
            ax.plot(t, ref_ang[:, idx], color=colors_ref, lw=1.5, label="reference")
            ax.plot(t, act_ang[:, idx], color=colors_act, lw=1.2, alpha=0.9, label="actual")
            _style_axis(ax, f"angular velocity {label}", "velocity [rad/s]")
        for col, (label, idx) in enumerate(axes_labels):
            ax = axs2[1, col]
            ax.plot(t, ref_force[:, idx], color=colors_ref, lw=1.5, label="reference")
            ax.plot(t, act_force[:, idx], color=colors_act, lw=1.2, alpha=0.9, label="actual")
            _style_axis(ax, f"force {label}", "force [N]")
        if save:
            wrench_path = save.with_name(save.stem + "_wrench" + save.suffix)
            fig2.savefig(wrench_path, dpi=160)
            print(f"Saved {wrench_path}")
        if show:
            fig2.show()
    else:
        fig3, axs3 = plt.subplots(1, 3, figsize=(14, 3.5), constrained_layout=True)
        fig3.suptitle(f"Angular velocity\n{topic}", fontsize=13, fontweight="bold")
        for col, (label, idx) in enumerate(axes_labels):
            ax = axs3[col]
            ax.plot(t, ref_ang[:, idx], color=colors_ref, lw=1.5, label="reference")
            ax.plot(t, act_ang[:, idx], color=colors_act, lw=1.2, alpha=0.9, label="actual")
            _style_axis(ax, f"angular velocity {label}", "velocity [rad/s]")
        if save:
            ang_path = save.with_name(save.stem + "_angular" + save.suffix)
            fig3.savefig(ang_path, dpi=160)
            print(f"Saved {ang_path}")
        if show:
            fig3.show()

    if save:
        fig.savefig(save, dpi=160)
        print(f"Saved {save}")

    if show:
        plt.show()
    else:
        plt.close(fig)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("mcap", type=Path, help="Path to the .mcap recording")
    parser.add_argument(
        "--topic",
        help="Telemetry topic (default: auto-detect *cartesian_trajectory_telemetry*)",
    )
    parser.add_argument("--save", type=Path, help="Save main figure to this path (e.g. plot.png)")
    parser.add_argument("--no-show", action="store_true", help="Do not open an interactive window")
    args = parser.parse_args()

    if not args.mcap.is_file():
        raise SystemExit(f"File not found: {args.mcap}")

    topic, samples = load_samples(args.mcap, args.topic)
    print(f"Loaded {len(samples)} samples from '{topic}' ({samples[-1].t - samples[0].t:.2f} s)")

    plot_samples(samples, topic, args.save, show=not args.no_show)


if __name__ == "__main__":
    main()
