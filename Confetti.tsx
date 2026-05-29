"use client"

import { animate, type DOMKeyframesDefinition, motion } from "motion/react"
import { useEffect, useRef, useState } from "react"

/** ==============   Props   ================ */

interface ConfettiProps {
    particleCount?: number
    startVelocity?: number
    spread?: number
    decay?: number
    gravity?: number
    drift?: number
    duration?: number
    size?: number
    colors?: string[]
    buttonSpring?: { stiffness: number; damping: number }
}

/** ==============   Component   ================ */

export default function Confetti({
    particleCount = 60,
    startVelocity = 25,
    spread = 100,
    decay = 0.91,
    gravity = 1,
    drift = 0,
    duration = 2.5,
    size = 1,
    colors = COLORS,
    buttonSpring = { stiffness: 400, damping: 15 },
}: ConfettiProps = {}) {
    const [bursts, setBursts] = useState<Burst[]>([])
    const nextId = useRef(0)

    const handleBurst = () => {
        const id = nextId.current++
        const ticks = Math.round(duration * 60)

        const particles: Particle[] = Array.from(
            { length: particleCount },
            () => {
                const radSpread = spread * (Math.PI / 180)
                const angle =
                    -Math.PI / 2 + (0.5 * radSpread - Math.random() * radSpread)
                const velocity =
                    startVelocity * 0.5 + Math.random() * startVelocity
                const wobbleSpeed = Math.min(0.11, Math.random() * 0.1 + 0.05)
                const wobbleOffset = Math.random() * 10
                const pieceSize = 6 * size + Math.random() * 6 * size
                const tiltRotations = 2 + Math.random() * 4
                const rotation = Math.random() * 360

                const keyframes = computeKeyframes({
                    angle,
                    startVelocity: velocity,
                    decay,
                    gravity,
                    drift,
                    wobbleSpeed,
                    wobbleOffset,
                    size,
                    ticks,
                    tiltRotations,
                    rotation,
                })

                return {
                    keyframes,
                    duration,
                    size: pieceSize,
                    color: colors[Math.floor(Math.random() * colors.length)],
                    shape: SHAPES[Math.floor(Math.random() * SHAPES.length)],
                }
            }
        )

        setBursts((prev) => [...prev, { id, particles }])

        setTimeout(
            () => setBursts((prev) => prev.filter((b) => b.id !== id)),
            (duration + 0.5) * 1000
        )
    }

    return (
        <div style={wrapperStyle}>
            <div style={burstContainerStyle}>
                {bursts.map((burst) => (
                    <div key={burst.id} style={particleLayerStyle}>
                        {burst.particles.map((p, i) => (
                            <ConfettiPiece key={i} particle={p} />
                        ))}
                    </div>
                ))}

                <motion.button
                    className="confetti-trigger"
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    transition={{
                        type: "spring",
                        ...buttonSpring,
                    }}
                    onClick={handleBurst}
                >
                    <CelebrationIcon />
                    <span>Celebrate</span>
                </motion.button>
            </div>
            <Stylesheet />
        </div>
    )
}

/** ==============   Particle   ================ */

interface Particle {
    keyframes: DOMKeyframesDefinition
    duration: number
    size: number
    color: string
    shape: "circle" | "rect" | "strip"
}

interface Burst {
    id: number
    particles: Particle[]
}

const ConfettiPiece = ({ particle }: { particle: Particle }) => {
    const ref = useRef<HTMLDivElement>(null)
    const { keyframes, duration, size, color, shape } = particle

    const width =
        shape === "strip" ? size * 0.3 : shape === "rect" ? size * 0.7 : size
    const height = shape === "strip" ? size * 2 : size
    const borderRadius =
        shape === "circle" ? "50%" : shape === "strip" ? size * 0.12 : 2

    useEffect(() => {
        if (!ref.current) return
        const animation = animate(ref.current, keyframes, {
            duration,
            ease: "linear",
        })
        return () => animation.cancel()
    }, [])

    return (
        <div
            ref={ref}
            style={{
                position: "absolute",
                width,
                height,
                borderRadius,
                backgroundColor: color,
                willChange: "transform, opacity",
                pointerEvents: "none",
            }}
        />
    )
}

/** ==============   Physics   ================ */

/**
 * Physics model derived from canvas-confetti by Kiril Vatev
 * Copyright (c) 2020, Kiril Vatev — ISC License
 * https://github.com/catdad/canvas-confetti
 *
 * We're pre-generating transform keyframes so the animation
 * can run entirely on the GPU.
 */

const KEYFRAME_STEPS = 40
const SCALE_DURATION_FRACTION = 0.08

const computeKeyframes = (params: {
    angle: number
    startVelocity: number
    decay: number
    gravity: number
    drift: number
    wobbleSpeed: number
    wobbleOffset: number
    size: number
    ticks: number
    tiltRotations: number
    rotation: number
}) => {
    const {
        angle,
        startVelocity,
        decay,
        gravity,
        drift,
        wobbleSpeed,
        wobbleOffset,
        size,
        ticks,
        tiltRotations,
        rotation,
    } = params

    const transform: string[] = []
    const opacity: number[] = []

    let velocity = startVelocity
    let x = 0
    let y = 0
    let wobble = wobbleOffset
    let tick = 0

    for (let step = 0; step <= KEYFRAME_STEPS; step++) {
        const t = step / KEYFRAME_STEPS

        // Physics simulation
        if (step > 0) {
            const targetTick = Math.round((step * ticks) / KEYFRAME_STEPS)
            while (tick < targetTick) {
                x += Math.cos(angle) * velocity + drift
                y += Math.sin(angle) * velocity + gravity * 3
                velocity *= decay
                wobble += wobbleSpeed
                tick++
            }
        }

        const wx = step === 0 ? 0 : x + Math.cos(wobble) * 15 * size
        const wy = y

        // Scale: 0 → 1.15 → 1 over first ~8% of duration
        let scale: number
        if (t < SCALE_DURATION_FRACTION * 0.6) {
            scale = (t / (SCALE_DURATION_FRACTION * 0.6)) * 1.15
        } else if (t < SCALE_DURATION_FRACTION) {
            const st =
                (t - SCALE_DURATION_FRACTION * 0.6) /
                (SCALE_DURATION_FRACTION * 0.4)
            scale = 1.15 - st * 0.15
        } else {
            scale = 1
        }

        // RotateY: linear over full duration
        const rotateY = tiltRotations * 360 * t

        // Opacity: hold 1 until 50%, fade to 0.5 at 80%, then 0
        let opacityKeyframe: number
        if (t <= 0.5) {
            opacityKeyframe = 1
        } else if (t <= 0.8) {
            opacityKeyframe = 1 - ((t - 0.5) / 0.3) * 0.5
        } else {
            opacityKeyframe = 0.5 - ((t - 0.8) / 0.2) * 0.5
        }

        transform.push(
            `translate(${wx}px, ${wy}px) scale(${scale}) rotateY(${rotateY}deg) rotate(${rotation}deg)`
        )
        opacity.push(opacityKeyframe)
    }

    return { transform, opacity }
}

/** ==============   Icon   ================ */

const CelebrationIcon = () => (
    <svg
        width="16"
        height="16"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2.5"
        strokeLinecap="round"
        strokeLinejoin="round"
    >
        <path d="M5.8 11.3 2 22l10.7-3.79" />
        <path d="M4 3h.01" />
        <path d="M22 8h.01" />
        <path d="M15 2h.01" />
        <path d="M22 20h.01" />
        <path d="m22 2-2.24.75a2.9 2.9 0 0 0-1.96 3.12c.1.86-.57 1.63-1.45 1.63h-.38c-.86 0-1.6.6-1.76 1.44L14 10" />
        <path d="m22 13-.82-.33c-.86-.34-1.82.2-1.98 1.11c-.11.7-.72 1.22-1.43 1.22H17" />
        <path d="m11 2 .33.82c.34.86-.2 1.82-1.11 1.98C9.52 4.9 9 5.52 9 6.23V7" />
        <path d="M11 13c1.93 1.93 2.83 4.17 2 5-.83.83-3.07-.07-5-2-1.93-1.93-2.83-4.17-2-5 .83-.83 3.07.07 5 2Z" />
    </svg>
)

/** ==============   Data   ================ */

const COLORS = [
    "#26ccff",
    "#a25afd",
    "#ff5e7e",
    "#88ff5a",
    "#fcff42",
    "#ffa62d",
    "#ff36ff",
]

const SHAPES: Particle["shape"][] = ["circle", "rect", "rect", "strip", "strip"]

/** ==============   Styles   ================ */

const wrapperStyle: React.CSSProperties = {
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    width: "100%",
    height: "100dvh",
    overflow: "hidden",
}

const burstContainerStyle: React.CSSProperties = {
    position: "relative",
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
}

const particleLayerStyle: React.CSSProperties = {
    position: "absolute",
    top: "50%",
    left: "50%",
    pointerEvents: "none",
    zIndex: 10000,
}

function Stylesheet() {
    return (
        <style>{`
            .confetti-trigger {
                position: relative;
                display: inline-flex;
                align-items: center;
                gap: 8px;
                padding: 10px 16px;
                font-size: 14px;
                font-weight: 500;
                font-family: inherit;
                color: var(--white);
                background: var(--layer);
                border: 1px solid var(--border);
                border-radius: 10px;
                cursor: pointer;
                z-index: 1;
                user-select: none;
                -webkit-user-select: none;
                will-change: transform;
                transition: background-color 0.15s;
            }
            .confetti-trigger:hover {
                background-color: rgba(255, 255, 255, 0.08);
            }
        `}</style>
    )
}
