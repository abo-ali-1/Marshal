export interface Config {
	fallbackResourceName: string;
	allowEscapeKey: boolean;
}

export interface vec2 {
	x: number;
	y: number;
}

export interface vec3 {
	x: number;
	y: number;
	z: number;
}

export interface vec4 {
	x: number;
	y: number;
	z: number;
	w: number;
}

export interface polyzone {
	points: vec3[];
	name?: string;
	thickness?: number;
}

export interface PlayerGang {
	name: string;
	grade: string;
	isboss?: boolean;
}

export interface Player {
	name: string;
	gang: PlayerGang;
	serverId: number;
	citizenId?: string;
	coord: vec2;
}

export interface Gang {
	name: string;
	label: string;
	color: string;
	logoURL?: string;
	money?: number;
	territory?: polyzone;
	loyalty?: number;
	warWinRate?: number;
	polygon?: any;
	marker?: any;
}

export interface TributeZone {
	name: string;
	label: string;
	imageURL: string;
	territory: polyzone;
	captureTimerLabel?: string;
	owner?: string | null;
	captureDate?: number;
	paymentAmount: number;
	paymentResetTime?: number;
	paymentResetTimeText?: string;
	polygon?: any;
	marker?: any;
}

export interface War {
	id: number;
	initiator: string;
	target: string;
	initiatorScore: number;
	targetScore: number;
	killGoal: number;
	wager: number;
	accepted?: boolean;
	cancelled?: boolean;
	surrendered?: number;
	declareDate?: number;
	acceptRejectDate?: number;
	finishDate?: number;

	initiatorLogoURL?: string;
	targetLogoURL?: string;
	initiatorLabelText?: string;
	targetLabelText?: string;
}

export interface TurfWar {
	id: number;
	initiator: string;
	target: string;
	declareDate: number;
	startDate: number;
	finishDate: number;
	started?: boolean;
	initiatorPersonCount?: number;
	targetPersonCount?: number;
	successful?: boolean;

	startDateText?: string;
	finishDateText?: string;
}

export interface Announcement {
	text: string;
	time: number;
	icon?: string;
}

export interface TributeEventData {
	finishDate: number;
	points: Record<string, number>;
	zoneLabel: string;
}

export interface LocationInfo {
	type: string;
	name: string;
}

export interface WarFeedData {
	id?: number;
	initiator: string;
	target: string;
	initiatorScore: number;
	targetScore: number;
	highlightedSide?: string;
	started?: boolean;
	finished?: boolean;

	initiatorLabelText?: string;
	targetLabelText?: string;
	initiatorLogoURL?: string;
	targetLogoURL?: string;
}

export interface Notification {
	id: number;
	text: string;
	icon?: string;
}
