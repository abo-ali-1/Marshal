import { DebugEventCallback } from '@typings/events';
import { ReceiveEvent } from './eventsHandlers';
import { ANNOUNCEMENTS, TRIBUTE_EVENT_DATA, CONFIG, GANGS, PLAYER, TRIBUTE_ZONES, TURF_WARS, TURF_EVENT_ID, VISIBLE, WARS, LOCATION_INFO, WAR_FEED } from '@stores/stores';
import type { Gang, Player, PlayerGang, TributeZone, TurfWar, War, TributeEventData, LocationInfo, WarFeedData } from '@typings/misc';
import { get } from 'svelte/store';
import { calculateTurfDominance, calculateWarWinRate, getGangData, getGangLabelText, notify } from '@utils/misc';
import { default as locales, setLocale } from '@utils/locales';

let showEventNotificationsToEveryone: boolean = true;
let locationInfoTimer: number = 4000;
let isGang: boolean = false;

const AlwaysListened: DebugEventCallback[] = [
	{
		action: 'setup',
		handler: (data: {
			locales: typeof locales;
			cfg: {
				tributePaymentInterval: number;
				turfWarLoyalty: number;
				warLoyaltyPerKill: number;
				timeAgoLocale: string;
				showEventNotificationsToEveryone: boolean;
				locationInfoTimer: number;
				warMinWager: number;
				warMaxWager: number;
				warMinKillGoal: number;
				warMaxKillGoal: number;
				locationInfoPosition: string;
				notificationPosition: string;
				notificationPositionWhenInterfaceOpen: string;
				tributeScoreboardPosition: string;
				turfScoreboardPosition: string;
				warFeedPosition: string;
			};
			gangs: Gang[];
			tributeZones: TributeZone[];
			wars: War[];
			turfWars: TurfWar[];
		}) => {
			setLocale(data.locales);

			showEventNotificationsToEveryone = data.cfg.showEventNotificationsToEveryone;
			locationInfoTimer = data.cfg.locationInfoTimer;

			CONFIG.update((config) => {
				return {
					...config,
					timeAgoLocale: data.cfg.timeAgoLocale ?? 'en_US',
					tributePaymentInterval: data.cfg.tributePaymentInterval,
					turfWarLoyalty: data.cfg.turfWarLoyalty,
					warLoyaltyPerKill: data.cfg.warLoyaltyPerKill,
					warMinWager: data.cfg.warMinWager,
					warMaxWager: data.cfg.warMaxWager,
					warMinKillGoal: data.cfg.warMinKillGoal,
					warMaxKillGoal: data.cfg.warMaxKillGoal,
					locationInfoPosition: data.cfg.locationInfoPosition,
					notificationPosition: data.cfg.notificationPosition,
					notificationPositionWhenInterfaceOpened: data.cfg.notificationPositionWhenInterfaceOpen,
					tributeScoreboardPosition: data.cfg.tributeScoreboardPosition,
					turfScoreboardPosition: data.cfg.turfScoreboardPosition,
					warFeedPosition: data.cfg.warFeedPosition,
				};
			});

			WARS.set(data.wars);
			TURF_WARS.set(data.turfWars);

			data.gangs = data.gangs.map((gang) => {
				return { ...gang, warWinRate: calculateWarWinRate(gang.name), logoURL: gang.logoURL ?? 'https://placehold.co/500' };
			});
			GANGS.set(data.gangs);

			let announcements = [];

			data.tributeZones.forEach((zone) => {
				if (zone.captureDate && zone.owner) {
					const owner = getGangData(zone.owner);
					const ownerText = getGangLabelText(owner.label, owner.color);
					announcements.push({
						text: `${locales.tribute_taken_over.format(ownerText, zone.label)}(${locales.$}${zone.paymentAmount}).`,
						icon: 'map-location-dot',
						time: zone.captureDate,
					});
				}
			});
			TRIBUTE_ZONES.set(data.tributeZones);

			data.wars.forEach((war) => {
				const initiator = getGangData(war.initiator);
				const target = getGangData(war.target);
				const initiatorText = getGangLabelText(initiator.label, initiator.color);
				const targetText = getGangLabelText(target.label, target.color);
				if (war.finishDate) {
					if (war.surrendered === 1) {
						announcements.push({
							text: `${locales.war_surrender.format(targetText, initiatorText, targetText, initiatorText)} <b>${locales.score}:</b> ${war.targetScore}/${war.initiatorScore} <b>${locales.wager}:</b> ${locales.$}${war.wager}`,
							icon: 'flag',
							time: war.finishDate,
						});
					} else if (war.surrendered === 2) {
						announcements.push({
							text: `${locales.war_surrender.format(initiatorText, initiatorText, targetText, targetText)} <b>${locales.score}:</b> ${war.initiatorScore}/${war.targetScore} <b>${locales.wager}:</b> ${locales.$}${war.wager}`,
							icon: 'flag',
							time: war.finishDate,
						});
					} else if (war.initiatorScore == war.targetScore) {
						announcements.push({
							text: `${locales.war_end_draw.format(initiatorText, targetText)} <b>${locales.wager}:</b> ${locales.$}${war.wager}`,
							icon: 'flag-checkered',
							time: war.finishDate,
						});
					} else if (war.targetScore > war.initiatorScore) {
						announcements.push({
							text: `${locales.war_end.format(targetText, initiatorText, targetText)} <b>${locales.score}:</b> ${war.targetScore}/${war.initiatorScore} <b>${locales.wager}:</b> ${locales.$}${war.wager}`,
							icon: 'flag-checkered',
							time: war.finishDate,
						});
					} else {
						announcements.push({
							text: `${locales.war_end.format(initiatorText, initiatorText, targetText)} <b>${locales.score}:</b> ${war.initiatorScore}/${war.targetScore} <b>${locales.wager}:</b> ${locales.$}${war.wager}`,
							icon: 'flag-checkered',
							time: war.finishDate,
						});
					}
				}

				if (war.accepted) {
					announcements.push({
						text: `${locales.war_accect.format(targetText, initiatorText)} <b>${locales.wager}:</b> ${locales.$}${war.wager}`,
						icon: 'check',
						time: war.acceptRejectDate,
					});
				} else if (war.accepted == false) {
					announcements.push({
						text: `${locales.war_reject.format(targetText, initiatorText)}`,
						icon: 'face-sad-cry',
						time: war.acceptRejectDate,
					});
				} else if (war.cancelled == true) {
					announcements.push({
						text: `${locales.war_cancel.format(initiatorText, targetText, war.killGoal)}`,
						icon: 'ban',
						time: war.acceptRejectDate,
					});
				}

				announcements.push({
					text: `${locales.war_declare.format(initiatorText, targetText, war.killGoal)} <b>${locales.wager}:</b> ${locales.$}${war.wager}`,
					icon: 'crosshairs',
					time: war.declareDate,
				});
			});

			data.turfWars.forEach((war) => {
				const initiator = getGangData(war.initiator);
				const target = getGangData(war.target);
				const initiatorText = getGangLabelText(initiator.label, initiator.color);
				const targetText = getGangLabelText(target.label, target.color);
				const dominance = calculateTurfDominance(war.initiatorPersonCount, war.targetPersonCount);
				if (war.successful !== undefined) {
					if (war.successful) {
						announcements.push({
							text: `${locales.turf_war_end.format(initiatorText, initiatorText, targetText)} <b>${locales.dom}:</b> %${dominance.winner}`,
							icon: 'shield',
							time: war.finishDate,
						});
					} else {
						announcements.push({
							text: `${locales.turf_war_end.format(targetText, initiatorText, targetText)} <b>${locales.dom}:</b> %${dominance.winner}`,
							icon: 'shield',
							time: war.finishDate,
						});
					}
				}

				if (war.finishDate) {
					announcements.push({
						text: `${locales.turf_war_started.format(initiatorText, targetText, targetText)}`,
						icon: 'shield',
						time: war.startDate,
					});
				}

				if (war.startDate) {
					announcements.push({
						text: `${locales.turf_war_starting.format(initiatorText, targetText)}`,
						icon: 'shield',
						time: war.declareDate,
					});
				}
			});

			ANNOUNCEMENTS.set(announcements.sort((a, b) => a.time - b.time));

			let announcementsWrapper = document.getElementById('announcementsWrapper');
			if (announcementsWrapper) setTimeout(() => announcementsWrapper.scroll({ top: announcementsWrapper.scrollHeight, behavior: 'smooth' }), 10);
		},
	},
	{
		action: 'unload',
		handler: () => {
			PLAYER.set(undefined);
			TRIBUTE_ZONES.set(undefined);
			GANGS.set(undefined);
			WARS.set(undefined);
			TURF_WARS.set(undefined);
			ANNOUNCEMENTS.set(undefined);
			VISIBLE.set(false);
		},
	},
	{
		action: 'open',
		handler: (data: { player: Player }) => {
			isGang = !!get(GANGS).find(({ name }) => name === data.player.gang.name);
			PLAYER.set(data.player);
			VISIBLE.set(true);
		},
	},
	{
		action: 'tributeEventScoreboard',
		handler: (data?: TributeEventData) => {
			TRIBUTE_EVENT_DATA.set(data);
		},
	},
	{
		action: 'turfEventScoreboard',
		handler: (turfWarId?: number) => {
			TURF_EVENT_ID.set(turfWarId);
		},
	},
	{
		action: 'locationInfo',
		handler: (data: LocationInfo) => {
			LOCATION_INFO.set(data);
			if (data?.type && locationInfoTimer > -1) setTimeout(() => LOCATION_INFO.set(null), locationInfoTimer ?? 4000);
		},
	},
	{
		action: 'notify',
		handler: (data: { text: string; type?: string }) => {
			if (data.text) notify(data.text, undefined, data.type == 'error' && 'circle-xmark');
		},
	},
	{
		action: 'warFeed',
		handler: (data: WarFeedData) => {
			const newId = Math.floor(Math.random() * 99999);
			const initiator = getGangData(data.initiator);
			const target = getGangData(data.target);
			WAR_FEED.update((feed) => [
				...feed,
				{
					...data,
					id: newId,
					initiatorLabelText: getGangLabelText(initiator.label, initiator.color),
					targetLabelText: getGangLabelText(target.label, target.color),
					initiatorLogoURL: initiator.logoURL,
					targetLogoURL: target.logoURL,
				},
			]);
			setTimeout(() => {
				WAR_FEED.update((feed) => feed.filter(({ id }) => id != newId));
			}, 4500);
		},
	},
	{
		action: 'update',
		handler: (data: { playerGang?: PlayerGang; tributeZone?: { name: string; owner?: string; captureDate?: number; paymentResetTime?: number }; loyalty?: { gangName: string; newPoint: number }; war?: War; turfWar?: TurfWar; logoURL?: { gangName: string; url: string }; money?: { gangName: string; amount: number } }) => {
			if (data.playerGang) {
				isGang = !!get(GANGS).find(({ name }) => name === data.playerGang.name);
				PLAYER.update((player) => {
					return { ...player, gang: data.playerGang };
				});
			}

			if (data.logoURL) {
				GANGS.update((gangs) => {
					return gangs.map((gang) => {
						if (gang.name == data.logoURL.gangName) return { ...gang, logoURL: data.logoURL.url };
						else return gang;
					});
				});
			}

			if (data.tributeZone) {
				TRIBUTE_ZONES.update((zones) => {
					return zones.map((zone) => {
						if (zone.name == data.tributeZone.name) {
							if (data.tributeZone.owner) {
								let announcements = get(ANNOUNCEMENTS);
								const owner = getGangData(data.tributeZone.owner);
								const ownerText = getGangLabelText(owner.label, owner.color);
								const announcement = {
									text: `${locales.tribute_taken_over.format(ownerText, zone.label)}</b>(${locales.$}${zone.paymentAmount}).`,
									icon: 'map-location-dot',
									time: data.tributeZone.captureDate,
								};
								announcements.push(announcement);
								if (showEventNotificationsToEveryone || isGang) notify(announcement.text, 'bottomCenter', announcement.icon);
								ANNOUNCEMENTS.set(announcements.sort((a, b) => a.time - b.time));
								let announcementsWrapper = document.getElementById('announcementsWrapper');
								if (announcementsWrapper) setTimeout(() => announcementsWrapper.scroll({ top: announcementsWrapper.scrollHeight, behavior: 'smooth' }), 10);
							}

							return { ...zone, owner: data.tributeZone.owner ?? zone.owner, captureDate: data.tributeZone.captureDate ?? zone.captureDate, paymentResetTime: data.tributeZone.paymentResetTime };
						} else return zone;
					});
				});
			}

			if (data.loyalty) {
				GANGS.update((gangs) => {
					return gangs.map((gang) => {
						if (gang.name == data.loyalty.gangName && gang.loyalty != data.loyalty.newPoint) return { ...gang, loyalty: data.loyalty.newPoint };
						else return gang;
					});
				});
			}

			if (data.money) {
				GANGS.update((gangs) => {
					return gangs.map((gang) => {
						if (gang.name == data.money.gangName && gang.money != data.money.amount) return { ...gang, money: data.money.amount };
						else return gang;
					});
				});
			}

			if (data.war) {
				let wars = get(WARS);
				let announcements = get(ANNOUNCEMENTS);

				const initiator = getGangData(data.war.initiator);
				const target = getGangData(data.war.target);
				const initiatorText = getGangLabelText(initiator.label, initiator.color);
				const targetText = getGangLabelText(target.label, target.color);

				let warIndex = wars.findIndex((war) => war.id == data.war.id);
				if (warIndex > -1) {
					let existingWar = wars[warIndex];
					if (existingWar.finishDate === undefined && data.war.finishDate !== undefined) {
						if (existingWar.surrendered === undefined && data.war.surrendered !== undefined) {
							if (data.war.surrendered == 1) {
								const announcement = {
									text: `${locales.war_surrender.format(targetText, initiatorText, targetText, initiatorText)} <b>${locales.score}:</b> ${data.war.targetScore}/${data.war.initiatorScore} <b>${locales.wager}:</b> ${locales.$}${data.war.wager}`,
									icon: 'flag',
									time: data.war.finishDate,
								};
								if (showEventNotificationsToEveryone || isGang) notify(announcement.text, 'bottomCenter', announcement.icon);
								announcements.push(announcement);
							} else if (data.war.surrendered == 2) {
								const announcement = {
									text: `${locales.war_surrender.format(initiatorText, initiatorText, targetText, targetText)} <b>${locales.score}:</b> ${data.war.initiatorScore}/${data.war.targetScore} <b>${locales.wager}:</b> ${locales.$}${data.war.wager}`,
									icon: 'flag',
									time: data.war.finishDate,
								};
								if (showEventNotificationsToEveryone || isGang) notify(announcement.text, 'bottomCenter', announcement.icon);
								announcements.push(announcement);
							}
						} else {
							if (data.war.initiatorScore == data.war.targetScore) {
								const announcement = {
									text: `${locales.war_end_draw.format(initiatorText, targetText)} <b>${locales.wager}:</b> ${locales.$}${data.war.wager}`,
									icon: 'flag-checkered',
									time: data.war.finishDate,
								};
								if (showEventNotificationsToEveryone || isGang) notify(announcement.text, 'bottomCenter', announcement.icon);
								announcements.push(announcement);
							} else if (data.war.targetScore > data.war.initiatorScore) {
								const announcement = {
									text: `${locales.war_end.format(targetText, initiatorText, targetText)} <b>${locales.score}:</b> ${data.war.targetScore}/${data.war.initiatorScore} <b>${locales.wager}:</b> ${locales.$}${data.war.wager}`,
									icon: 'flag-checkered',
									time: data.war.finishDate,
								};
								if (showEventNotificationsToEveryone || isGang) notify(announcement.text, 'bottomCenter', announcement.icon);
								announcements.push(announcement);
							} else {
								const announcement = {
									text: `${locales.war_end.format(initiatorText, initiatorText, targetText)} <b>${locales.score}:</b> ${data.war.initiatorScore}/${data.war.targetScore} <b>${locales.wager}:</b> ${locales.$}${data.war.wager}`,
									icon: 'flag-checkered',
									time: data.war.finishDate,
								};
								if (showEventNotificationsToEveryone || isGang) notify(announcement.text, 'bottomCenter', announcement.icon);
								announcements.push(announcement);
							}
						}
					} else if (existingWar.cancelled === undefined && data.war.cancelled !== undefined) {
						const announcement = {
							text: `${locales.war_cancel.format(initiatorText, targetText, data.war.killGoal)}`,
							icon: 'ban',
							time: data.war.acceptRejectDate,
						};
						if (showEventNotificationsToEveryone || isGang) notify(announcement.text, 'bottomCenter', announcement.icon);
						announcements.push(announcement);
					} else if (existingWar.accepted == undefined && data.war.accepted != undefined) {
						if (data.war.accepted) {
							const announcement = {
								text: `${locales.war_accect.format(targetText, initiatorText)} <b>${locales.wager}:</b> ${locales.$}${data.war.wager}`,
								icon: 'check',
								time: data.war.acceptRejectDate,
							};
							if (showEventNotificationsToEveryone || isGang) notify(announcement.text, 'bottomCenter', announcement.icon);
							announcements.push(announcement);
						} else {
							const announcement = {
								text: `${locales.war_reject.format(targetText, initiatorText)}`,
								icon: 'face-sad-cry',
								time: data.war.acceptRejectDate,
							};
							if (showEventNotificationsToEveryone || isGang) notify(announcement.text, 'bottomCenter', announcement.icon);
							announcements.push(announcement);
						}
					}
					wars[warIndex] = data.war;
				} else {
					wars.push(data.war);
					const announcement = {
						text: `${locales.war_declare.format(initiatorText, targetText, data.war.killGoal)} <b>${locales.wager}:</b> ${locales.$}${data.war.wager}`,
						icon: 'crosshairs',
						time: data.war.declareDate,
					};
					if (showEventNotificationsToEveryone || isGang) notify(announcement.text, 'bottomCenter', announcement.icon);
					announcements.push(announcement);
				}

				WARS.set(wars);
				ANNOUNCEMENTS.set(announcements.sort((a, b) => a.time - b.time));

				let announcementsWrapper = document.getElementById('announcementsWrapper');
				if (announcementsWrapper) setTimeout(() => announcementsWrapper.scroll({ top: announcementsWrapper.scrollHeight, behavior: 'smooth' }), 10);

				GANGS.update((gangs) => {
					return gangs.map((gang) => {
						if (gang.name == initiator.name || gang.name == target.name) return { ...gang, warWinRate: calculateWarWinRate(gang.name) };
						else return gang;
					});
				});
			}

			if (data.turfWar) {
				let turfWars = get(TURF_WARS);
				let announcements = get(ANNOUNCEMENTS);

				const initiator = getGangData(data.turfWar.initiator);
				const target = getGangData(data.turfWar.target);
				const initiatorText = getGangLabelText(initiator.label, initiator.color);
				const targetText = getGangLabelText(target.label, target.color);

				let warIndex = turfWars.findIndex((war) => war.id == data.turfWar.id);
				if (warIndex > -1) {
					let existingWar = turfWars[warIndex];
					if (existingWar.successful === undefined && data.turfWar.successful !== undefined) {
						const dominance = calculateTurfDominance(data.turfWar.initiatorPersonCount, data.turfWar.targetPersonCount);
						if (data.turfWar.successful) {
							const announcement = {
								text: `${locales.turf_war_end.format(initiatorText, initiatorText, targetText)} <b>${locales.dom}:</b> %${dominance.winner}`,
								icon: 'shield',
								time: data.turfWar.finishDate,
							};
							if (showEventNotificationsToEveryone || isGang) notify(announcement.text, 'bottomCenter', announcement.icon);
							announcements.push(announcement);
						} else {
							const announcement = {
								text: `${locales.turf_war_end.format(targetText, initiatorText, targetText)} <b>${locales.dom}:</b> %${dominance.winner}`,
								icon: 'shield',
								time: data.turfWar.finishDate,
							};
							if (showEventNotificationsToEveryone || isGang) notify(announcement.text, 'bottomCenter', announcement.icon);
							announcements.push(announcement);
						}
					} else if (existingWar.started === undefined && data.turfWar.started) {
						const announcement = {
							text: `${locales.turf_war_started.format(initiatorText, targetText, targetText)}`,
							icon: 'shield',
							time: data.turfWar.startDate,
						};
						if (showEventNotificationsToEveryone || isGang) notify(announcement.text, 'bottomCenter', announcement.icon);
						announcements.push(announcement);
					}
					turfWars[warIndex] = data.turfWar;
				} else {
					const announcement = {
						text: `${locales.turf_war_starting.format(initiatorText, targetText)}`,
						icon: 'shield',
						time: data.turfWar.declareDate,
					};
					if (showEventNotificationsToEveryone || isGang) notify(announcement.text, 'bottomCenter', announcement.icon);
					announcements.push(announcement);
					turfWars.push(data.turfWar);
				}

				TURF_WARS.set(turfWars);
				ANNOUNCEMENTS.set(announcements.sort((a, b) => a.time - b.time));

				let announcementsWrapper = document.getElementById('announcementsWrapper');
				if (announcementsWrapper) setTimeout(() => announcementsWrapper.scroll({ top: announcementsWrapper.scrollHeight, behavior: 'smooth' }), 10);

				GANGS.update((gangs) => {
					return gangs.map((gang) => {
						if (gang.name == initiator.name || gang.name == target.name) return { ...gang, warWinRate: calculateWarWinRate(gang.name) };
						else return gang;
					});
				});
			}
		},
	},
];

export default AlwaysListened;

export function InitialiseListen() {
	for (const debug of AlwaysListened) {
		ReceiveEvent(debug.action, debug.handler);
	}
}
