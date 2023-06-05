use std::{path::PathBuf, fs};
use sys_mount::{Mount, MountFlags};

fn main() {
    println!("Hello, world!");
    do_overlay().unwrap();

    println!("we must have finished OK");
}

fn do_overlay() -> std::io::Result<()> {
    fs::create_dir_all("/overlay")?;

    let overlay_dir = PathBuf::from("/overlay");

    // Check environment variable for overlay path
    if let Ok(overlay) = std::env::var("overlay_root") {
        if overlay == "ram" {
            let _mount = Mount::builder()
                .fstype("tmpfs")
                .flags(MountFlags::NOATIME)
                .data("mode=0755")
                .mount("tmpfs", &overlay_dir)?;
        } else {
            let overlay_device_path = PathBuf::from("/dev").join(overlay);

            

            let _mount = Mount::builder()
                .fstype("ext4")
                .mount(overlay_device_path, &overlay_dir)?;
        }
    }

    fs::create_dir_all(overlay_dir.join("work"))?;
    fs::create_dir_all(overlay_dir.join("root"))?;

    pivot()?;

    Ok(())
}

fn pivot() -> std::io::Result<()> {
    let root = PathBuf::from("/overlay/root");
    let work = PathBuf::from("/overlay/work");
    let _mount = Mount::builder()
        .fstype("overlay")
        .flags(MountFlags::NOATIME)
        .data(&format!("lowerdir=/,upperdir={},workdir={}", root.display(), work.display()))
        .mount("overlayfs:/overlay/root", "/mnt")?;

    fs::create_dir_all("/mnt/rom")?;

    nix::unistd::pivot_root("/mnt", "/mnt/rom")?;

    Ok(())
}