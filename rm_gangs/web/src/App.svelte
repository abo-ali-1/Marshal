<script lang="ts">
	import { CONFIG, LOCATION_INFO, TRIBUTE_EVENT_DATA, TURF_EVENT_ID, VISIBLE, WAR_FEED } from './stores/stores';
	import { InitialiseListen } from '@utils/listeners';
	import Visibility from '@providers/Visibility.svelte';
	import Main from '@layouts/Main.svelte';
	import Notifications from '@layouts/Notifications.svelte';
	import { DebugEventSend } from '@utils/eventsHandlers';

	import TurfScoreboard from '@layouts/TurfScoreboard.svelte';
	import TributeScoreboard from '@layouts/TributeScoreboard.svelte';
	import LocationInfo from '@layouts/LocationInfo.svelte';
	import WarFeed from '@layouts/WarFeed.svelte';

	// CONFIG.set({
	// 	fallbackResourceName: 'debug',
	// 	allowEscapeKey: true,
	// 	timeAgoLocale: 'en_US',
	// });

	DebugEventSend(
		'setup',
		{
			cfg: {
				tributePaymentInterval: 2,
				turfWarLoyalty: 500,
				warLoyaltyPerKill: 10,

				locationInfoPosition: 'bottom-right',
				notificationPosition: 'bottom-center',
				notificationPositionWhenInterfaceOpen: 'top-left',
				tributeScoreboardPosition: 'bottom-right',
				turfScoreboardPosition: 'bottom-right',
				warFeedPosition: 'top-right',
			},
			gangs: [
				{
					name: 'ballas',
					label: 'Ballas',
					logoURL: 'https://static.wikia.nocookie.net/callmekevin/images/1/18/Kisspng-sean-sweet-johnson-grove-street-families-applica-leezaampaposs-content-phoenixrp-5bf04711480997.3455555715424734892951.png',
					color: '#790CF5',
					money: 0,
					territory: {
						points: [
							{ x: 234.0, y: -598.0 },
							{ x: 351.0, y: -640.0 },
							{ x: 418.0, y: -540.0 },
							{ x: 261.0, y: -537.0 },
						],
					},
					loyalty: 31,
				},
				{
					name: 'grove',
					label: 'Grove Street Families',
					logoURL: 'https://static.wikia.nocookie.net/callmekevin/images/1/18/Kisspng-sean-sweet-johnson-grove-street-families-applica-leezaampaposs-content-phoenixrp-5bf04711480997.3455555715424734892951.png',
					color: '#790CF5',
					money: 0,
					territory: {
						points: [
							{ x: 234.0, y: -598.0 },
							{ x: 351.0, y: -640.0 },
							{ x: 418.0, y: -540.0 },
							{ x: 261.0, y: -537.0 },
						],
					},
					loyalty: 31,
				},
				{
					name: 'vagos',
					label: 'Vagos the vagos galapagos',
					logoURL: 'https://prod.cloud.rockstargames.com/crews/sc/8817/39845942/publish/emblem/emblem_512.png',
					color: '#EEF50C',
					money: 0,
					territory: {
						points: [
							{ x: 371.6216216216218, y: -1720.1219512195116 },
							{ x: 445.5236486486488, y: -1633.2317073170725 },
							{ x: 228.3421814671816, y: -1448.7804878048773 },
							{ x: 166.50579150579165, y: -1415.2439024390237 },
							{ x: 91.09555984555999, y: -1505.1829268292677 },
						],
					},
					loyalty: 26,
				},
			],
			tributeZones: [
				{
					name: 'suds_law_laundromat',
					label: 'Suds Law Laundromat',
					imageURL: 'https://static.wikia.nocookie.net/gtawiki/images/d/d6/TheBrewer%27sDrop-GTAV.jpg',
					paymentAmount: 1500,
					paymentResetTime: 1709740800000,
					territory: {
						points: [
							{ x: 56.150001525879, y: -1543.2000732422, z: 32.5 },
							{ x: 128.60000610352, y: -1604.0, z: 32.5 },
							{ x: 139.94999694824, y: -1597.5, z: 32.5 },
							{ x: 142.19999694824, y: -1595.0, z: 32.5 },
							{ x: 143.10000610352, y: -1591.9499511719, z: 32.5 },
							{ x: 142.75, y: -1589.0500488281, z: 32.5 },
							{ x: 140.55000305176, y: -1586.25, z: 32.5 },
							{ x: 69.800003051758, y: -1526.9499511719, z: 32.5 },
						],
					},
					captureTimerLabel: 'on Thu at 08:00 PM',
					owner: 'ballas',
					captureDate: 1709722800000,
				},
				{
					name: 'the_taco_farmer',
					label: 'The Taco Farmer',
					imageURL: 'https://static.wikia.nocookie.net/gtawiki/images/2/2a/LaserPrints-GTAV.jpg',
					paymentAmount: 1000,
					territory: {
						points: [
							{ x: 3.3499999046326, y: -1604.5999755859, z: 31.1 },
							{ x: 20.700000762939, y: -1619.0, z: 31.1 },
							{ x: 35.0, y: -1601.0, z: 31.1 },
							{ x: 17.64999961853, y: -1587.5999755859, z: 31.1 },
						],
					},
					captureTimerLabel: 'on Wed at 08:00 PM',
					// owner: 'vagos',
					captureDate: 1709726400000,
				},
			],
			wars: [
				{
					id: 1,
					initiator: 'vagos',
					target: 'ballas',
					initiatorScore: 15,
					targetScore: 12,
					killGoal: 15,
					wager: 250,
					accepted: true,
					declareDate: 1709290800000,
					acceptRejectDate: 1709377200000,
					finishDate: 1709463600000,
				},
				{
					id: 2,
					initiator: 'vagos',
					target: 'ballas',
					initiatorScore: 15,
					targetScore: 12,
					killGoal: 15,
					wager: 250,
					accepted: true,
					declareDate: 1709290800000,
					acceptRejectDate: 1709377200000,
					// finishDate: 1709463600000,
				},
				{
					id: 3,
					initiator: 'vagos',
					target: 'ballas',
					initiatorScore: 0,
					targetScore: 0,
					killGoal: 15,
					wager: 250,
					// accepted: true,
					declareDate: 1709290800000,
					// acceptRejectDate: 1709377200000,
					// finishDate: 1709463600000,
				},
				{
					id: 4,
					initiator: 'vagos',
					target: 'grove',
					initiatorScore: 0,
					targetScore: 3,
					killGoal: 15,
					wager: 250,
					accepted: true,
					surrendered: 1,
					// cancelled: true,
					declareDate: 1709290800000,
					acceptRejectDate: 1709377200000,
					finishDate: 1709463600000,
				},
				{
					id: 5,
					initiator: 'grove',
					target: 'ballas',
					initiatorScore: 15,
					targetScore: 12,
					killGoal: 15,
					wager: 250,
					accepted: true,
					declareDate: 1709290800000,
					acceptRejectDate: 1709377200000,
					// finishDate: 1709463600000,
				},
			],
			turfWars: [
				{
					id: 1,
					initiator: 'vagos',
					target: 'ballas',
					declareDate: 1709290800000,
					startDate: 1709377200000,
					finishDate: 1709377200000,
					successful: true,
					initiatorPersonCount: 10,
					targetPersonCount: 2,
				},
				{
					id: 2,
					initiator: 'ballas',
					target: 'vagos',
					declareDate: 1709290800000,
					startDate: 1709377200000,
					finishDate: 1709377200000,
					started: true,
					initiatorPersonCount: 1,
					targetPersonCount: 0,
				},
			],
		},
		10
	);

	// DebugEventSend('turfEventScoreboard', 2, 10);

	// DebugEventSend(
	// 	'tributeEventScoreboard',
	// 	{
	// 		zoneLabel: 'The Taco Farmer',
	// 		finishDate: 1710321755000,
	// 		points: {
	// 			ballas: 10,
	// 			vagos: 40,
	// 		},
	// 	},
	// 	10
	// );

	DebugEventSend(
		'open',
		{
			player: {
				name: 'vex test',
				serverId: 31,
				citizenId: '123AS51',
				gang: {
					name: 'ballas',
					grade: 'Boss',
					isboss: true,
				},
				coord: { x: 311.0, y: -556.0 },
			},
		},
		10
	);

	// DebugEventSend(
	// 	'locationInfo',
	// 	{
	// 		type: 'tributeZone',
	// 		name: 'the_taco_farmer',
	// 	},
	// 	10
	// );

	DebugEventSend(
		'notify',
		{
			type: 'error',
			text: 'test notification',
		},
		10
	);

	// DebugEventSend(
	// 	'warFeed',
	// 	{
	// 		initiator: 'ballas',
	// 		target: 'vagos',
	// 		initiatorScore: 8,
	// 		targetScore: 5,
	// 		finished: true,
	// 		highlightedSide: 'initiator',
	// 	},
	// 	10
	// );

	// DebugEventSend(
	// 	'update',
	// 	{
	// 		war: {
	// 			id: 4,
	// 			initiator: 'ballas',
	// 			target: 'grove',
	// 			killGoal: 15,
	// 			acceptRejectDate: 1739210698000,
	// 			cancelled: true,
	// 		},
	// 	},
	// 	10
	// );

	InitialiseListen();
</script>

<Notifications />

<Visibility>
	<Main />
</Visibility>

{#if !$VISIBLE}
	{#if $TURF_EVENT_ID}
		<TurfScoreboard />
	{:else if $TRIBUTE_EVENT_DATA}
		<TributeScoreboard />
	{/if}

	{#if $LOCATION_INFO}
		<LocationInfo />
	{/if}

	{#if $WAR_FEED.length > 0}
		<WarFeed />
	{/if}
{/if}

<!-- {#if $IS_BROWSER}
	{#await import('./providers/Debug.svelte') then { default: Debug }}
		<Debug />
	{/await}
{/if} -->
