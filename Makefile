.PHONY: all clean check

all:| patch_helper.sh

patch.sh.in.enc: patch.sh.in
	base64 patch.sh.in > patch.sh.in.enc

patch_helper.sh: patch_helper.sh.in patch.sh.in.enc
	sed patch_helper.sh.in -e "/@__PATCH_SCRIPT__@/r patch.sh.in.enc" -e "/@__PATCH_SCRIPT__@/d" > patch_helper.sh

clean:
	rm -f patch.sh.in.enc patch_helper.sh

check: patch_helper.sh.in patch.sh.in
	shellcheck patch_helper.sh.in
	shellcheck patch.sh.in