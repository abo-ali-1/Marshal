import type { Announcement, TributeEventData, Gang, Player, TributeZone, TurfWar, War, LocationInfo, WarFeedData, Notification } from '@typings/misc';
import { get, writable } from 'svelte/store';

export const PLAYER = writable<Player>();
export const TRIBUTE_ZONES = writable<TributeZone[]>([]);
export const GANGS = writable<Gang[]>([]);
export const WARS = writable<War[]>([]);
export const TURF_WARS = writable<TurfWar[]>([]);
export const ANNOUNCEMENTS = writable<Announcement[]>([]);

export const NOTIFICATIONS = writable<Notification[]>([]);
export const TRIBUTE_EVENT_DATA = writable<TributeEventData>();
export const TURF_EVENT_ID = writable<number>();
export const LOCATION_INFO = writable<LocationInfo>();
export const WAR_FEED = writable<WarFeedData[]>([]);

export const MODAL_VISIBLE = writable<boolean>(false);

export const CONFIG = writable<any>({
	/** Fallback resource name for when the resource name cannot be found. */
	fallbackResourceName: 'debug',

	/** Whether the escape key should make visibility false. */
	allowEscapeKey: true,
	timeAgoLocale: 'en_US',

	warMinWager: 0,
	warMaxWager: 10000,
	warMinKillGoal: 10,
	warMaxKillGoal: 1000,

	locationInfoPosition: 'bottom-right',
	notificationPosition: 'bottom-center',
	notificationPositionWhenInterfaceOpened: 'top-left',
	tributeScoreboardPosition: 'bottom-right',
	turfScoreboardPosition: 'bottom-right',
	warFeedPosition: 'top-right',
});

/**
 * The name of the resource. This is used for the resource manifest.
 * @type {Writable<string>}
 */
export const RESOURCE_NAME = writable<string>((window as any).GetParentResourceName ? (window as any).GetParentResourceName() : get(CONFIG).fallbackResourceName);

/**
 * Whether the current environment is the browser or the client.
 * @type {Writable<boolean>}
 */
export const IS_BROWSER = writable<boolean>(!(window as any).invokeNative);

/**
 * Whether the debug menu is visible or not.
 * @type {Writable<boolean>}
 */
export const VISIBLE = writable<boolean>(false);
