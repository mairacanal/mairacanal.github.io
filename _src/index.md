---
title : About me
permalink : /about-me/
---

```rust
// ~/mairacanal.rs

impl AboutMe
{
    fn getCurrentWorkplace()->& str {
        "Igalia Coding Experience"
    }

    fn getCurrentDegree() -> Degree {
        Degree {
            course: "Computer Engineering",
            university : "University of São Paulo",
            onGoing : true,
        }
    }

    fn getDailyKnowledge() -> Vec<&str> {
        vec![
            "C/C++",
            "Rust",
            "Data Structures",
            "Linux Kernel",
            "Yocto",
            "FreeRTOS",
            "Computer Architecture",
            "Embedded Systems",
            "ARM",
            "Vim",
        ]
    }

    fn getOpenSourceProjects() -> Vec<&str> {
        vec![
            "Linux Kernel, especially the DRM subsystem",
            "igt-gpu-tools",
            "Mesa",
            "VK-GL-CTS",
            "LLVM",
            "meta-openembedded",
        ]
    }

    fn getMyLinks() -> Vec<&str> {
        vec ![
            "https://www.linkedin.com/in/mairacanal/",
            "https://mairacanal.github.io/",
        ]
    }

    fn getFutureGoal() -> &str
    {
        "Learn more about RISC-V, Rust and GPU architecture."
    }
}
```
---

Interested in what I have to share? Here's [my blog](/)

Want to know what I'm coding? Check [my github](https://github.com/mairacanal/)
or [my gitlab](https://gitlab.freedesktop.org/mairacanal).

Color of this website hurts your eyes? No problem, pick your favorite base16
colors at my [colorscheme picker](/colorscheme/).

Wanna talk me? My email and social networks are down here `\/`
