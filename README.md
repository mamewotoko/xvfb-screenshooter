# xvfb-screenshooter

Take screenhosts and videos from your xvfb-session.

xvfb-screenshooter is a wrapper to run and record arbitrary GUI programs.

They will be run via  xvfb-run (which itself is a script to run stuff in Xvfb) and
xvfb-screenshooter will record this via `avconv` and will take a screenshot with
`xwd` each second. [Read more](https://inktrap.org/xvfb-screenshooter.html)


## setup

1. install dependencies

```
apt install -y imagemagick ffmpeg x11-apps
```

## run

```
./xvfb-screenshooter.sh CMD
```
