import glob
for path in sorted(glob.glob("datasets/*.csv")):
    head = open(path, "rb").read(2000).split(b"\n", 1)[0]
    print(path, "-> CRLF" if head.endswith(b"\r") else "-> LF")