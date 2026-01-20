#!/bin/bash

XMX=$(get_from_env "XMX" "format(^[0-9]+[KMGT]$)" "4096M" "upper,trim")
XMS=$(get_from_env "XMS" "format(^[0-9]+[KMGT]$)" "2048M" "upper,trim")

if [ -t 0 ]; then
  dterm_jline_default="true"
else
  dterm_jline_default="false"
fi
DTERM_JLINE=$(get_from_env "DTERM_JLINE" "boolean" "$dterm_jline_default" "trim")
DTERM_ANSI=$(get_from_env "DTERM_ANSI" "boolean" "true" "trim")

GC_TYPE=$(get_from_env "GC_TYPE" "enum(g1gc, zgc)" "g1gc" "lower")

gc_args_base=""
case "$GC_TYPE" in
  "g1gc")
    gc_args_base="-XX:+UseG1GC -XX:MaxGCPauseMillis=200" ;;
  "zgc")
    gc_args_base="-XX:+UseZGC" ;;
esac
gc_args_base="$gc_args_base -XX:+AlwaysPreTouch -XX:+UnlockExperimentalVMOptions -XX:+ParallelRefProcEnabled"
GC_ARGS=$(get_from_env "GC_ARGS" "string" "$gc_args_base" "trim")

USE_AOT=$(get_from_env "USE_AOT" "boolean" "false" "trim")
aot_arg=""
if [ "$USE_AOT" = "true" ]; then
  aot_arg="-XX:AOTCache=HytaleServer.aot"
fi

jvm_args_default="-Xms$XMS -Xmx$XMX -Dterminal.jline=$DTERM_JLINE -Dterminal.ansi=$DTERM_ANSI $GC_ARGS $aot_arg"
JVM_ARGS=$(get_from_env "JVM_ARGS" "string" "$jvm_args_default" "trim")