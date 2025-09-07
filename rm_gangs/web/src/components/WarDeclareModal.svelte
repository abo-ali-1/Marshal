<script lang="ts">
	import { CONFIG, PLAYER } from '@stores/stores';
	import Modal from '@layouts/Modal.svelte';
	import { createForm } from 'svelte-forms-lib';
	import { getGangLabelText } from '@utils/misc';
	import { SendEvent } from '@utils/eventsHandlers';
	import type { Gang } from '@typings/misc';
	import locales from '@utils/locales';

	export let show: boolean;
	export let target: Gang;

	const { form, handleChange, handleSubmit } = createForm({
		initialValues: {
			killGoal: 15,
			wager: 0,
		},
		onSubmit: (values) => {
			SendEvent('declareWar', { target: target.name, killGoal: values.killGoal, wager: values.wager });
			show = false;
		},
	});
</script>

<Modal bind:show>
	<div class="min-w-[30vw] flex flex-col gap-4 py-2 px-4">
		<div class="flex gap-4">
			<img class="w-[10vw] h-[10vw] border-gray-700 border" src={target.logoURL} alt="logo url" />
			<div class="flex flex-col gap-4">
				<div class="text-4xl">
					{@html getGangLabelText(target.label, target.color)}
				</div>
				<div class="flex flex-col gap-1 text-xl text-[1.3rem]">
					<div>
						<b>{locales.loyalty_point}: </b>
						{target.loyalty}
					</div>
					<div>
						<b>{locales.war_win_rate}: </b>
						%{target.warWinRate}
					</div>
				</div>
			</div>
		</div>
		<form on:submit={handleSubmit} class="flex flex-col gap-4">
			<div>
				<div class="text-gray-400 text-lg pb-1">{locales.kill_goal}</div>
				<div class="flex items-center border border-gray-600">
					<i class="text-gray-500 fa-solid fa-skull-crossbones px-2 w-[2vw]" />
					<input type="number" class="bg-transparent text-gray-300 w-full py-2.5 pl-1 appearance-none" disabled={!$PLAYER.gang.isboss} on:change={handleChange} bind:value={$form.killGoal} min={$CONFIG.warMinKillGoal} max={$CONFIG.warMaxKillGoal} />
				</div>
			</div>
			<div>
				<div class="text-gray-400 text-lg pb-1">{locales.wager}</div>
				<div class="flex items-center border border-gray-600">
					<i class="text-gray-500 fa-solid fa-money-bill px-2 w-[2vw]" />
					<input type="number" class="bg-transparent text-gray-300 w-full py-2.5 pl-1 appearance-none" disabled={!$PLAYER.gang.isboss} on:change={handleChange} bind:value={$form.wager} min={$CONFIG.warMinWager} max={$CONFIG.warMaxWager} />
				</div>
			</div>

			<button class="bg-red-500 text-black rounded font-bold py-1 px-2 text-xl hover:bg-red-600" disabled={!$PLAYER.gang.isboss} type="submit">{locales.declare_war}</button>
		</form>
		<small class="flex gap-2 items-center text-gray-500">
			<i class="fa-solid fa-circle-info pt-[5px]" />
			{locales.loyalty_affect_info}:<b>{$form.killGoal * $CONFIG.warLoyaltyPerKill}</b>
		</small>
	</div>
</Modal>

<style>
	input[type='number']::-webkit-inner-spin-button,
	input[type='number']::-webkit-outer-spin-button {
		-webkit-appearance: none;
		margin: 0;
	}
</style>
