'use strict'

const getDependencies = (opt) => {
	const {
		tripsWithoutShapeId,
		routesWithoutAgencyId,
		stopsWithoutLevelId,
	} = opt
	return {
		agency: [
			'is_timezone',
		],
		stops: [
			'is_timezone',
			...(stopsWithoutLevelId ? [] : ['levels']),
		],
		transfers: [
			'stops',
		],
		stop_times: [
			'trips',
			'stops',
			'service_days',
			'frequencies',
		],
		routes: [
			...(routesWithoutAgencyId ? [] : ['agency']),
		],
		trips: [
			'routes',
			'service_days',
			...(tripsWithoutShapeId ? [] : ['shapes']),
		],
		frequencies: [
			'trips',
		],
		pathways: [
			'stops',
		],
		optimizations: [
			'stop_times',
			'routes',
			'calendar'
		]
	}
}

module.exports = getDependencies
