<script lang="ts">
	import Map from '@components/Map.svelte';
	import LogoModal from '@components/LogoModal.svelte';
	import { GANGS, PLAYER, TRIBUTE_ZONES, WARS, ANNOUNCEMENTS, TURF_WARS, VISIBLE, CONFIG } from '@stores/stores';
	import type { Gang, TributeZone, TurfWar, War } from '@typings/misc';
	import { SendEvent } from '@utils/eventsHandlers';
	import { fade } from 'svelte/transition';
	import { getGangData, getGangLabelText, getRemainingTime, notify } from '@utils/misc';
	import { onDestroy, onMount } from 'svelte';
	import WarDeclareModal from '@components/WarDeclareModal.svelte';
	import { format as timeAgo } from 'timeago.js';
	import locales from '@utils/locales';

	let gangLogoModal: boolean = false;
	let warDeclareModal: boolean = false;
	let warDeclareTarget: Gang;

	VISIBLE.subscribe((val) => {
		if (!val) {
			gangLogoModal = false;
			warDeclareModal = false;
			warDeclareTarget = null;
		}
	});

	let myGang: Gang;
	let myWarRequests: War[] = [];
	let myCurrentWars: War[] = [];
	let myTributeZones: TributeZone[] = [];
	let currentTurfWar: TurfWar;
	$: {
		myGang = $GANGS.find(({ name }) => name === $PLAYER.gang.name);
		myWarRequests = $WARS.filter(({ initiator, target, accepted, cancelled }) => (initiator == myGang?.name || target == myGang?.name) && accepted == undefined && cancelled == undefined).sort((a, b) => a.declareDate - b.declareDate);
		myTributeZones = $TRIBUTE_ZONES
			.filter(({ owner }) => owner == myGang?.name)
			.map((zone) => {
				const currentTimestamp = new Date().getTime();
				if (zone.paymentResetTime < currentTimestamp) {
					const resetTime = getRemainingTime(zone.paymentResetTime, currentTimestamp);
					return { ...zone, paymentResetTimeText: locales.timer_hm.format(resetTime.hour, resetTime.minute) };
				} else return { ...zone, paymentResetTimeText: undefined };
			});
		myCurrentWars = $WARS
			.filter(({ initiator, target, accepted, finishDate }) => (initiator == myGang?.name || target == myGang?.name) && accepted && finishDate === undefined)
			.sort((a, b) => a.acceptRejectDate - b.acceptRejectDate)
			.map((war) => {
				const initiator = getGangData(war.initiator);
				const initiatorLabelText = getGangLabelText(initiator.label, initiator.color);
				const target = getGangData(war.target);
				const targetLabelText = getGangLabelText(target.label, target.color);
				return { ...war, initiatorLabel: initiator.label, initiatorLabelText: initiatorLabelText, initiatorLogoURL: initiator.logoURL, targetLabel: target.label, targetLabelText: targetLabelText, targetLogoURL: target.logoURL };
			});
		currentTurfWar = $TURF_WARS.find(({ successful }) => successful === undefined);
	}

	const calculateTributePaymentRemainingTime = () => {
		if (myTributeZones.length > 0)
			myTributeZones = myTributeZones.map((zone) => {
				const currentTimestamp = new Date().getTime();
				if (zone.paymentResetTime > currentTimestamp) {
					const resetTime = getRemainingTime(zone.paymentResetTime, currentTimestamp);
					return { ...zone, paymentResetTimeText: locales.timer_hm.format(resetTime.hour, resetTime.minute) };
				} else return { ...zone, paymentResetTimeText: undefined };
			});
	};

	const calculateCurrentTurfWarRemainingTime = () => {
		if (!currentTurfWar) return;

		if (currentTurfWar.started) {
			const remainingTime = getRemainingTime(currentTurfWar.finishDate);
			currentTurfWar.finishDateText = locales.timer_ms.format(remainingTime.minute, remainingTime.second);
		} else if (currentTurfWar.started === undefined) {
			const remainingTime = getRemainingTime(currentTurfWar.startDate);
			currentTurfWar.startDateText = locales.timer_ms.format(remainingTime.minute, remainingTime.second);
		}
	};

	let interval: number;
	onMount(() => {
		interval = setInterval(() => {
			calculateTributePaymentRemainingTime();
			calculateCurrentTurfWarRemainingTime();
		}, 1000);

		let announcementsWrapper = document.getElementById('announcementsWrapper');
		if (announcementsWrapper) announcementsWrapper.scroll({ top: announcementsWrapper.scrollHeight, behavior: 'instant' });
	});

	onDestroy(() => {
		if (interval) clearTimeout(interval);
	});

	const replyToWarRequest = (warId: number, answer: boolean) => SendEvent('replyToWarRequest', { id: warId, answer: answer });
	const cancelWarRequest = (warId: number) => SendEvent('cancelWarRequest', { id: warId });
	const surrenderInWar = (warId: number) => SendEvent('surrenderInWar', { id: warId });

	(window as any).declareWar = (target: string) => {
		if ($PLAYER.gang.isboss) {
			warDeclareTarget = getGangData(target);
			warDeclareModal = true;
		} else notify(locales.only_bosses_can_declare_war);
	};

	(window as any).setOnGPS = (x: number, y: number) => {
		notify(locales.location_marked);
		SendEvent('setOnGPS', {
			x: x,
			y: y,
		});
	};
</script>

{#if myGang}
	<WarDeclareModal bind:show={warDeclareModal} target={warDeclareTarget} />
	<LogoModal bind:show={gangLogoModal} logoURL={myGang.logoURL} />
{/if}

<div class="w-screen h-screen absolute top-0 left-0 flex justify-center items-center" transition:fade={{ duration: 200 }}>
	<div class="w-full px-6 flex gap-6">
		<Map />
		<div class="w-[50%] flex flex-col gap-6 items-end">
			{#if myGang}
				<div class="w-full h-[65%]">
					<div class="w-full flex justify-between gap-3">
						<div class="basis-7/12 h-full flex flex-col gap-3">
							<div class="max-h-[24vh] flex flex-col gap-3 bg-primary border-2 border-gray-400 rounded-sm p-4 overflow-auto">
								<div class="text-gray-400 flex items-center gap-2 text-lg">
									<i class="fas fa-person-rifle {myCurrentWars.length > 0 ? 'fa-beat-fade' : ''}" />
									{locales.your_current_battles}
								</div>
								<div class="w-full flex flex-col text-xl tracking-wide divide-y divide-gray-600 pr-1">
									{#if myCurrentWars.length > 0}
										{#each myCurrentWars as war}
											<div class="flex items-center justify-between gap-3 py-2" transition:fade={{ duration: 300 }}>
												<div class="flex flex-1 shrink-0 gap-6 items-center">
													<img class="w-[3vw] h-[3vw] border-gray-700 border" src={war.initiatorLogoURL} alt="" />
													<div class="flex flex-col gap-4 text-2xl">
														<div class="w-[11vh] text-center truncate ...">
															{@html war.initiatorLabelText}
														</div>
														<div class="w-full text-center font-bold">{war.initiatorScore}</div>
													</div>
												</div>
												<div class="flex flex-col items-center">
													<div class="text-gray-400 italic">{locales.kill_goal}: {war.killGoal}</div>
													<div class="text-gray-400 italic">{locales.wager}: {locales.$}{war.wager}</div>
													{#if $PLAYER.gang.isboss}
														<button
															class="font-bold bg-yellow-100 text-black p-1 mt-1 text-base"
															on:click={() => {
																surrenderInWar(war.id);
															}}
														>
															{locales.surrender}
														</button>
													{/if}
												</div>
												<div class="flex flex-1 shrink-0 gap-6 items-center justify-end">
													<div class="flex flex-col gap-4 text-2xl">
														<div class="w-[11vh] text-center truncate ...">
															{@html war.targetLabelText}
														</div>
														<div class="w-full text-center font-bold">{war.accepted ? war.targetScore : locales.awaiting_reply}</div>
													</div>
													<img class="w-[3vw] h-[3vw] border-gray-700 border" src={war.targetLogoURL} alt="" />
												</div>
											</div>
										{/each}
									{:else}
										<div class="w-full flex justify-center items-center">
											<div class="flex gap-2 items-center">
												<i class="fa-solid fa-dove" />
												{locales.not_in_any_war}
											</div>
										</div>
									{/if}
								</div>
							</div>
							<div class="max-h-[23vh] flex flex-col gap-3 bg-primary border-2 border-gray-400 rounded-sm p-4 overflow-auto">
								<div class="text-gray-400 flex items-center gap-2 text-lg">
									<i class="fas fa-crosshairs {myWarRequests.length > 0 ? 'fa-beat-fade' : ''}" />
									{locales.war_requests}
								</div>
								<div class="w-full flex flex-col text-xl tracking-wide divide-y divide-gray-600 pr-1">
									{#if myWarRequests.length > 0}
										{#each myWarRequests as war}
											{#await getGangData(war.initiator != myGang?.name ? war.initiator : war.target) then gang}
												{#if gang}
													<div class="flex items-center gap-6 py-2" transition:fade={{ duration: 300 }}>
														<img class="w-[3vw] h-[3vw] border-gray-700 border" src={gang.logoURL} alt="" />
														<div class="w-full h-[5vh] flex flex-col justify-between">
															<div class="flex items-center justify-between">
																<div class="text-2xl">{@html getGangLabelText(gang.label, gang.color)}</div>
																<div class="pt-1 ml-auto mr-0 text-gray-400 text-xl text-right self-start text-[1.2rem]">{timeAgo(war.declareDate, $CONFIG.timeAgoLocale)}</div>
															</div>
															<div class="flex items-center justify-between">
																<div class="flex gap-2">
																	<div>
																		<b>{locales.kill_goal}:</b>
																		{war.killGoal}
																	</div>
																	<div>
																		<b>{locales.wager}:</b>
																		{locales.$}{war.wager}
																	</div>
																</div>
																<div class="flex gap-4">
																	{#if $PLAYER.gang.isboss}
																		{#if war.initiator == myGang?.name}
																			<button
																				class="font-bold bg-red-500 text-black p-1"
																				on:click={() => {
																					cancelWarRequest(war.id);
																				}}
																			>
																				{locales.cancel}
																			</button>
																		{:else}
																			<button
																				class="font-bold bg-green-400 text-black p-1"
																				on:click={() => {
																					replyToWarRequest(war.id, true);
																				}}
																			>
																				{locales.accept}
																			</button>
																			<button
																				class="font-bold bg-red-500 text-black p-1"
																				on:click={() => {
																					replyToWarRequest(war.id, false);
																				}}
																			>
																				{locales.reject}
																			</button>
																		{/if}
																	{/if}
																</div>
															</div>
														</div>
													</div>
												{/if}
											{/await}
										{/each}
									{:else}
										<div class="w-full flex justify-center items-center">
											<div class="flex gap-2 items-center">
												<i class="fa-solid fa-dove" />
												{locales.no_war_request}
											</div>
										</div>
									{/if}
								</div>
							</div>
							<div class="max-h-[12vh] flex flex-col gap-3 bg-primary border-2 border-gray-400 rounded-sm p-4">
								<div class="text-gray-400 flex items-center gap-2 text-lg">
									<i class="fas fa-shield {currentTurfWar ? 'fa-beat-fade' : ''}" />
									{locales.turf_wars}
								</div>
								<div class="w-full flex flex-col text-xl tracking-wide divide-y divide-gray-600 pr-1">
									{#if currentTurfWar}
										{#await [getGangData(currentTurfWar.initiator), getGangData(currentTurfWar.target)] then gangs}
											{#if gangs?.length == 2}
												<div class="flex items-center justify-between gap-3 py-2" transition:fade={{ duration: 300 }}>
													<div class="flex flex-1 shrink-0 gap-6 items-center">
														<img class="w-[3vw] h-[3vw] border-gray-700 border" src={gangs[0].logoURL} alt="" />
														<div class="flex flex-col text-2xl">
															<div class="text-gray-400 italic">{locales.attacker}</div>
															<div class="w-[11vh] truncate ...">
																{@html getGangLabelText(gangs[0].label, gangs[0].color)}
															</div>
														</div>
													</div>
													<div class="flex flex-col items-center gap-1">
														{#if currentTurfWar.finishDateText}
															<div class="text-gray-400 italic">{locales.time_left_to_finish}:</div>
															<div class="text-2xl font-bold">{currentTurfWar.finishDateText}</div>
														{:else if currentTurfWar.startDateText}
															<div class="text-gray-400 italic">{locales.time_left_to_start}:</div>
															<div class="text-2xl font-bold">{currentTurfWar.startDateText}</div>
														{/if}
													</div>
													<div class="flex flex-1 shrink-0 gap-6 items-center justify-end">
														<div class="flex flex-col text-2xl text-end">
															<div class="text-gray-400 italic">{locales.defender}</div>
															<div class="w-[11vh] truncate ...">
																{@html getGangLabelText(gangs[1].label, gangs[1].color)}
															</div>
														</div>
														<img class="w-[3vw] h-[3vw] border-gray-700 border" src={gangs[1].logoURL} alt="" />
													</div>
												</div>
											{/if}
										{/await}
									{:else}
										<div class="w-full flex justify-center items-center">
											<div class="flex gap-2 items-center">
												<i class="fa-solid fa-dove" />
												{locales.no_turf_war}
											</div>
										</div>
									{/if}
								</div>
							</div>
						</div>
						<div class="basis-5/12 h-full flex flex-col gap-3">
							<div class="h-min flex flex-col gap-3 bg-primary border-2 border-gray-400 rounded-sm p-4">
								<div class="text-gray-400 flex items-center gap-2 text-lg">
									<i class="fas fa-circle-info" />
									<div>{locales.personal_information}</div>
								</div>
								<div class="w-full flex flex-col gap-1 text-xl tracking-wide">
									<div>
										<b>{locales.id}: </b>
										{$PLAYER.serverId}
									</div>
									{#if $PLAYER.citizenId}
										<div>
											<b>{locales.citizen_id}: </b>
											{$PLAYER.citizenId}
										</div>
									{/if}
									<div>
										<b>{locales.name}: </b>
										{$PLAYER.name}
									</div>
									<div>
										<b>{locales.grade}: </b>
										{$PLAYER.gang.grade}
									</div>
								</div>
							</div>
							<div class="h-[35vh] flex flex-col gap-3 bg-primary border-2 border-gray-400 rounded-sm p-4">
								<div class="text-gray-400 flex items-center gap-2 text-lg">
									<i class="fas fa-users-between-lines" />
									<div>{locales.group_information}</div>
								</div>
								<!-- svelte-ignore a11y-click-events-have-key-events -->
								<!-- svelte-ignore a11y-no-noninteractive-element-interactions -->
								<div class="flex gap-2 tracking-wide">
									<img
										class="w-[5vw] h-[5vw] border-gray-700 border cursor-pointer"
										src={myGang.logoURL}
										alt="logo"
										title={locales.click_to_change_it}
										on:click={() => {
											gangLogoModal = true;
										}}
									/>
									<div class="w-[8vw] text-3xl font-bold break-words ...">{myGang.label}</div>
								</div>
								<div class="w-full flex flex-col gap-1 text-xl tracking-wide">
									<div>
										<b>{locales.money}: </b>
										{locales.$}{myGang.money ?? 0}
									</div>
									<div>
										<b>{locales.loyalty_point}: </b>
										{myGang.loyalty}
									</div>
									<div>
										<b>{locales.war_win_rate}: </b>
										%{myGang.warWinRate}
									</div>
									<div>
										<b>{locales.tribute_zones}: </b>
										{#if myTributeZones.length > 0}
											<ul class="list-disc ml-[0.8vw]">
												{@html myTributeZones.map(({ label, paymentAmount, paymentResetTimeText }) => `<li>${label} (${locales.$}${paymentAmount}) ${paymentResetTimeText ? ' | <span class="italic">' + locales.next_payment + ': ' + paymentResetTimeText + '</span>' : ' | <span class="italic">' + locales.payment_available + '</span>'}</li>`).join('')}
											</ul>
										{:else}
											{locales.no_tribute_zones}
										{/if}
									</div>
								</div>
							</div>
							<div class="h-min flex flex-col gap-3 bg-primary border-2 border-gray-400 rounded-sm p-4 overflow-auto">
								<div class="text-gray-400 flex items-center gap-2 text-lg">
									<i class="fas fa-ranking-star" />
									{locales.loyalty_point_leadership}
								</div>
								<div class="w-full flex flex-col gap-1 text-xl tracking-wide">
									{#each $GANGS.sort((a, b) => b.loyalty - a.loyalty).slice(0, 3) as gang, idx}
										<div class="flex justify-between items-center text-xl text-black font-bold px-2 py-1 rounded-sm" style="background: linear-gradient(90deg, {gang.color} 0%, #0a0a0a 99%);">
											<div class="flex gap-2">
												<div>#{idx + 1}</div>
												<div class="truncate ...">{gang.label}</div>
											</div>
											<div class="text-white">{gang.loyalty}</div>
										</div>
									{/each}
								</div>
							</div>
						</div>
					</div>
				</div>
			{/if}
			<div class="w-full flex flex-col gap-2 overflow-auto pr-1" style="max-height: {myGang ? '31vh' : '95vh'}" id="announcementsWrapper">
				{#each $ANNOUNCEMENTS as data}
					<div class="flex gap-3 pr-2 bg-primary rounded-sm" transition:fade={{ duration: 300 }}>
						<div class="w-[28px] flex justify-center items-center bg-gray-400 text-black text-[1.8rem]">
							<i class="fas fa-{data.icon ?? 'circle-exclamation'}" />
						</div>
						<div class="relative w-full">
							<div class="py-2 text-[1.5rem]">{@html data.text}</div>
							<div class="absolute pb-1 right-0 bottom-0 text-gray-400 text-xl text-right self-end text-[1.2rem]">{timeAgo(data.time, $CONFIG.timeAgoLocale)}</div>
						</div>
					</div>
				{/each}
			</div>
		</div>
	</div>
</div>
