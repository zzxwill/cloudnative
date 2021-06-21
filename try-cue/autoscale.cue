import "strconv"

output: {
	apiVersion: "standard.oam.dev/v1alpha1"
	kind:       "Autoscaler"
	spec: {
		minReplicas: parameter.min
		maxReplicas: parameter.max
		if parameter["cpuPercent"] != _|_ && parameter["cron"] != _|_ {
			triggers: [cpuScaler, cronScaler]
		}
		if parameter["cpuPercent"] != _|_ && parameter["cron"] == _|_ {
			triggers: [cpuScaler]
		}
		if parameter["cpuPercent"] == _|_ && parameter["cron"] != _|_ {
			triggers: [cronScaler]
		}
	}
}

cpuScaler: {
	type: "cpu"
	condition: {
		type: "Utilization"
		if parameter["cpuPercent"] != _|_ {
			// Temporarily use `strconv` for type converting. This bug will be fixed in kubevela#585
			value: strconv.FormatInt(parameter.cpuPercent, 10)
		}
	}
}

cronScaler: {
	type: "cron"
	if parameter["cron"] != _|_ && parameter.cron["replicas"] != _|_ {
		condition: {
			startAt:  parameter.cron.startAt
			duration: parameter.cron.duration
			days:     parameter.cron.days
			replicas: strconv.FormatInt(parameter.cron.replicas, 10)
			timezone: parameter.cron.timezone
		}
	}
}

parameter: #parameter
#parameter: {
	// +usage=Minimal replicas of the workload
	min: int
	// +usage=Maximal replicas of the workload
	max: int
	// +usage=Specify the value for CPU utilization, like 80, which means 80%
	// +alias=cpu-percent
	cpuPercent?: int
	// +usage=Cron type auto-scaling. Just for `appfile`, not available for Cli usage
	cron?: {
		// +usage=The time to start scaling, like `08:00`
		startAt: string
		// +usage=For how long the scaling will last
		duration: string
		// +usage=Several workdays or weekends, like "Monday, Tuesday"
		days: string
		// +usage=The target replicas to be scaled to
		replicas: int
		// +usage=Timezone, like "America/Los_Angeles"
		timezone: string
	}
}
