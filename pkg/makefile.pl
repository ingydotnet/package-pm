warn "1"x100;
stardoc_make_pod;
warn "2"x100;
readme_from $POD;
warn "3"x100;
ack_xxx;
all_from $PM;
version_check;
warn "9"x100;
