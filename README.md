## How to build

Clone this repo:

```
git clone https://github.com/safedns/openwrt-app.git $HOME/openwrt-app
```

Clone LEDE source tree:

```
git clone https://github.com/lede-project/source.git $HOME/source
```

Now add path to the application source to feeds config:

```
cd $HOME/source
echo "src-link custom $HOME/openwrt-app/src/" >> feeds.conf.default
```

Run:

```
./scripts/feeds update -a; ./scripts/feeds install -a
```

Then set building options for your platform:

```
make menuconfig
```

You must choose right target architecture, turn on luci-app-safedns(in LuCi--->Applications), luci-compat(in LuCi--->Modules) and safedns(in Network) options as modules (`M`, not (`Y` or `*`)). When you're done, run building:

```
make V=s
```

If your CPU has more than one core, you can run `make` with `-j$N`, where $N is
cores number plus one. `V=s` is for verbose output.

When building is complete you can find the packages at `bin/packages/$ARCH/custom`,
where $ARCH is your target architecture.

## For vendors

If you are a networking hardware vendor, we ask you to set user agent so that it contains hardware model and firmware version. In order to do it you should modify the [source](https://github.com/safedns/openwrt-app/blob/master/src/luci-app-safedns/luasrc/model/cbi/safedns/json_utils.lua#L46) before building.
