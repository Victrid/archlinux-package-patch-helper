# Arch Linux Patch Package Helper

A system for creating patch packages that can replace files from other packages without conflicts using pacman hooks. Sometimes you just want to replace a default file (e.g. remove the annoying cockpit motd which is hard-coded) but replacing it requires recompile the whole package again, as pacman will not allow two packages holding same file. This is for light weight patch-package that can do the exact job.

## Overview

This system allows you to create "patch packages" that can replace files from existing packages. When two packages both try to install files to the same location, pacman will report a conflict. This system solves this by:

1. **During installation**: Backing up the original file and replacing it with the patched version
2. **During removal**: Restoring the original file from backup
3. **During updates**: Properly handling file replacement in both pre- and post-transaction hooks

## Project Structure

### Core Files

- **`patch.sh.in`** - Template for the main patch management script (Bash-based)
- **`patch_helper.sh.in`** - Template for PKGBUILD integration helper script
- **`Makefile`** - Build system to generate the final `patch_helper.sh`

### Example Files

- **`example/PKGBUILD`** - Example patch package configuration
- **`example/20-connectivity.conf`** - Example patched configuration file

## Components

### 1. `patch.sh` - Bash Script
The main patch management script that handles:
- Patch package installation and removal
- Pacman hook generation
- Transaction handling (pre/post hooks)

### 2. `patch_helper.sh` - Shell Script
PKGBUILD integration helper that provides:
- `patch_build()` - Validation and hook generation during build()
- `patch_install()` - File installation during package()
- Automatic script generation from templates

## Building the Helper Script

The project uses a build system to generate the final `patch_helper.sh`:

```bash
# Build the helper script
make
```

## Usage

### Creating a Patch Package

Create a PKGBUILD with the following structure:

```bash
...

# Patch configuration
patch="networkmanager"
patch_pair_files=( dst_1 src_file_1 dst_2 src_file_2 )

build() {
    ...

    source "$srcdir/patch_helper.sh"
    patch_build
}

package() {
    ...

    source "$srcdir/patch_helper.sh"
    patch_install
}
```

### Required Variables in PKGBUILD

- `patch`: The name of the original package being patched
- `patch_pair_files`: Array of file pairs in format: `(original_path1 new_file1 original_path2 new_file2 ...)`

You also need to source and invoke them in `build` and `package` stages.

### Optional Configuration Variables

You can customize the patch system behavior by setting these optional variables in your PKGBUILD:

- `patch_script`: Name of the patch script to be stored in srcdir to prevent conflict (default: "patch.sh")
- `patch_info_name`: Name of the patch info file to be stored in srcdir to prevent conflict (default: "patch.info")
- `patch_location`: Directory where patch files are stored (default: "/usr/share/libalpm/patches")
- `patch_backup_dir`: Directory where backup files are stored (default: "/var/lib/libalpm/patches")
- `patch_debug`: Enable debug output (default: 0)

Example usage:
```bash
# Optional configuration
patch_script="custom-patch.sh"
patch_location="/usr/share/custom-patches"
patch_debug=1
```

## How It Works

### Installation Process
1. Patch package is installed via pacman
2. *Transaction*
3. Post-transaction hook triggers `patch.sh post-transaction`
4. Original files are backed up to `/var/lib/libalpm/patches/`
5. Patched files are copied to their target locations

### Removal Process
1. Patch package removal is initiated
2. Pre-transaction hook triggers `patch.sh uninstall`
3. Original files are restored from backup
4. Backup files are cleaned up
5. *Transaction*

### Update Process
1. Pre-transaction hook restores original files
2. *Transaction*
3. Post-transaction hook applies patches again

## Example: NetworkManager Patch

Here's a complete example for patching NetworkManager's connectivity configuration in example:

1. **Build the helper script**:
```bash
make
cp patch_helper.sh example/
```

2. **Build and install the patch package**:
```bash
cd example
makepkg
```

## Development

### Building and Testing

```bash
# Build the helper script
make

# Run shellcheck validation
make check

# Clean build artifacts
make clean
```

## License

This project is licensed under the MIT License.

<details>

<summary>Original Prompt</summary>


Write a Perl script, along with helper file patch_helper.sh. to generate a new type of *patch* package for Arch Linux. As two packages will conflict if both having a file in a same location, this kind of package will patch the original package, or, use the new file in this package to replace original package's installed file.

This should be done by pacman hooks. Take a fake package as an example: assume we have a package acme owning /usr/lib/acme.so, and a patch package acme-patch, dependent on acme want to replace /usr/lib/acme.so with acme-patch provided one. I think it should do the following job (it may be wrong, you should also check if there are other scenarios): 
- If this patch package is being installed, move /usr/lib/acme.so to a saved location, and move the patched acme.so to /usr/lib/acme.so
- If either patch package or original package is being updated, in Pre-transaction hook you restore, and in Post-transaction hook you patch the acme.so
- If the patch or original package is being removed (this will also remove the patch package, as patch is dependent on original one), restore and delete all backups in Pre-transaction hook.

The new files should installed in /usr/share/alpm-patch/{pkgname}/. You can place the original files in /var/lib/alpm-patch/{pkgname}/. You can create extra information in /usr/share/alpm-patch/{pkgname}/.

The script should read the PKGBUILD file (this is a bash script) for entries like `pkgname=“patch_package_name”`, `patch=“original_package”`, and `patch_pair_files=( /path/to/orig1 new_file_1 /path/to/orig2 new_file_2 ... )`. 

A invoke should look like:

```
# PKGBUILD file
pkgname=netconfig-patch
pkgver=0.0.1
pkgrel=1

patch=networkmanager
patch_pair_files=( /usr/lib/NetworkManager/conf.d/20-connectivity.conf new_connectivity.conf ) 
source=(
        <this script>
        new_connectivity.conf
        )
sha256sums=()

build() {
source <this script>

patch_build
}

install() {
source <this script>

patch_install
}

```

</details>
