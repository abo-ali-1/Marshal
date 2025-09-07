<script lang="ts">
	import { LOCATION_INFO, TRIBUTE_ZONES, CONFIG } from '@stores/stores';
	import { getGangData, getGangLabelText } from '@utils/misc';
	import { fade } from 'svelte/transition';
	import locales from '@utils/locales';

	let zoneData: any = {};
	$: {
		if ($LOCATION_INFO?.type === 'gang') {
			zoneData.type = 'gang';
			const gang = getGangData($LOCATION_INFO.name);
			zoneData.logoURL = gang.logoURL;
			zoneData.labelText = getGangLabelText(gang.label, gang.color);
		} else if ($LOCATION_INFO?.type === 'tributeZone') {
			zoneData.type = 'tributeZone';
			const tributeZone = $TRIBUTE_ZONES.find(({ name }) => name == $LOCATION_INFO.name);
			zoneData.labelText = `<b style="color: white">${tributeZone.label}</b>`;
			if (tributeZone.owner) {
				const gang = getGangData(tributeZone.owner);
				zoneData.logoURL = gang.logoURL;
				zoneData.ownerLabelText = getGangLabelText(gang.label, gang.color);
			} else {
				zoneData.logoURL = './blips/money_blip.png';
				zoneData.ownerLabelText = `<b style="color: white">${locales.unclaimed}</b>`;
			}
		} else zoneData = {};
	}
</script>

{#if $LOCATION_INFO}
	<div class={`${$CONFIG.locationInfoPosition} flex items-center justify-center bg-transparent opacity-80`} transition:fade={{ duration: 100 }}>
		<div class="border-gray-400 border bg-primary rounded-sm flex flex-col p-3">
			<div class="text-gray-400 flex items-center gap-2 text-lg self-center">
				<i class="fas fa-map-location-dot fa-beat-fade" />
				{locales.location_info}
			</div>

			<div class="flex flex-col gap-3 py-2">
				<div class="flex gap-2 items-center">
					{#if zoneData.logoURL}
						<img class="w-[2vw] h-[2vw] border-gray-700 border" src={zoneData.logoURL} alt="logo" />
					{/if}
					<div class="flex flex-col">
						<div class="text-2xl">
							{@html zoneData.labelText}
							{#if zoneData.type == 'gang'}{locales.territory}{/if}
						</div>
						{#if zoneData.type == 'tributeZone'}
							<div class="text-gray-400 gap-2 text-lg">
								{locales.owner}: {@html zoneData.ownerLabelText}
							</div>
						{/if}
					</div>
				</div>
			</div>
		</div>
	</div>
{/if}
