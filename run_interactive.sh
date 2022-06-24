docker run -it --rm --env DISPLAY=unix$DISPLAY -v $XAUTH:/root/.Xauthority -v /tmp/.X11-unix:/tmp/.X11-unix -w /arcsim arcsim-ubuntu bash
