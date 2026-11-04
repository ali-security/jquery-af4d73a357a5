#!/bin/sh
# Seal fork CI helper (Travis after_script). Travis archives job log parts
# asynchronously, minutes behind the job; the log harvested right after the
# build finishes can stop mid-run. Keep this job open until its own public
# log already contains the result summary of the leg's test command.
# after_script cannot change the build result.
#
# Usage: sh test/seal-wait-for-log.sh grunt|qunit
# (the regex lives here, not on the command line, so the echoed command
# itself can never satisfy it)
case "$1" in
	grunt) pattern='Done, without errors\.|Aborted due to warnings\.|Fatal error:' ;;
	qunit) pattern='QUnit summary: [0-9]' ;;
	*) echo "unknown leg: $1"; exit 0 ;;
esac
url="https://api.travis-ci.com/v3/job/${TRAVIS_JOB_ID}/log.txt"
i=0
# 120 polls x 20 s = 40 min cap; one heartbeat line per poll keeps Travis'
# 10-minute no-output watchdog from killing the job while the archive lags.
while [ $i -lt 120 ]; do
	if curl -sfL "$url" 2>/dev/null | grep -Eq "$pattern"; then
		echo "Job log archive contains the $1 result summary."
		exit 0
	fi
	i=$((i + 1))
	echo "waiting for the job log archive ($((i * 20))s)"
	sleep 20
done
echo "Job log archive still lacks the $1 result summary after 40 minutes."
exit 0
