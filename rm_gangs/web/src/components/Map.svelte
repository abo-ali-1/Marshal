<script lang="ts">
	import { onMount } from 'svelte';
	import L from 'leaflet';
	import 'leaflet/dist/leaflet.css';
	import { CONFIG, GANGS, PLAYER, TRIBUTE_ZONES, WARS } from '@stores/stores';
	import type { polyzone } from '@typings/misc';
	import { canDeclareWar } from '@utils/misc';
	import locales from '@utils/locales';

	let map: L.Map | undefined;
	let mapElement: HTMLElement;
	let mapBounds: L.LatLngBounds;

	const customCRS = L.extend({}, L.CRS.Simple, {
		projection: L.Projection.LonLat,
		scale: function (zoom: number) {
			return Math.pow(2, zoom);
		},
		zoom: function (sc: number) {
			return Math.log(sc) / 0.6931471805599453;
		},
		distance: function (pos1: { lng: number; lat: number }, pos2: { lng: number; lat: number }) {
			const x_difference = pos2.lng - pos1.lng;
			const y_difference = pos2.lat - pos1.lat;

			return Math.sqrt(x_difference * x_difference + y_difference * y_difference);
		},
		transformation: new L.Transformation(0.02072, 117.3, -0.0205, 172.8),
		infinite: false,
	});

	const convertPointsToLatlng = (polyzone: polyzone): [number, number][] => {
		return polyzone.points.map((coord) => [coord.y, coord.x]);
	};

	(window as any).closePopup = () => {
		if (map) map.closePopup();
	};

	onMount(async () => {
		if (!map) {
			map = L.map(mapElement, {
				maxBoundsViscosity: 1.0,
				maxZoom: 6,
				minZoom: 3,
				crs: customCRS,
				attributionControl: false,
				zoomControl: false,
				preferCanvas: true,
			});

			mapBounds = new L.LatLngBounds(map.unproject([0, 1024], 2), map.unproject([1024, 0], 2));
			map.setMaxBounds(mapBounds);
			L.imageOverlay('./map.webp', mapBounds).addTo(map);
			mapElement.style.backgroundColor = '#727272';
		}
		map.setView([$PLAYER.coord.y, $PLAYER.coord.x], 5);

		const gangs = await Promise.all(
			$GANGS.map(async (data) => {
				const latlngs = convertPointsToLatlng(data.territory);
				const polygon = L.polygon(latlngs, { color: data.color, fillOpacity: 0.7, weight: 1 }).addTo(map);
				const center = polygon.getCenter();
				const icon = L.icon({
					iconUrl: data.logoURL ?? './blips/gang_blip.png',
					iconSize: [15, 15],
				});
				const marker = L.marker(center, { icon: icon }).addTo(map);

				const clickHandler = async () => {
					map.flyTo(center, 6, {
						animate: true,
						duration: 1.5,
					});

					setTimeout(async () => {
						const tributeZones = $TRIBUTE_ZONES.filter((zone) => zone.owner == data.name);
						let zoneList = tributeZones.map((zone) => `<li>${zone.label}</li>`).join('');
						if (zoneList.length < 1) zoneList = `<li>${locales.doesnt_have_tribute_zone}</li>`;
						const wars = $WARS.filter((war) => (war.initiator == data.name || war.target == data.name) && war.accepted && war.finishDate === undefined);
						let enemyList = '';
						wars.forEach((war) => {
							if (war.initiator == data.name) {
								const label = $GANGS.find((gang) => gang.name == war.target)?.label ?? locales.unknown;
								enemyList = `<li>${label}</li>${enemyList}`;
							} else if (war.target == data.name) {
								const label = $GANGS.find((gang) => gang.name == war.initiator)?.label ?? locales.unknown;
								enemyList = `<li>${label}</li>${enemyList}`;
							}
						});
						if (enemyList.length < 1) enemyList = `<li>${locales.doesnt_have_enemy}</li>`;
						const popupContent = `
                            <div class="w-full flex flex-wrap gap-2 bg-primary">
                                <img class="w-[30%] border-gray-700 border" src="${data.logoURL ?? 'https://placehold.co/500'}" alt="" />
                                <div class="text-2xl font-bold text-white break-words ...">${data.label}</div>
                                <div class="w-full flex flex-col gap-1 text-lg">
                                    <div>
                                        <b>${locales.loyalty_point}: </b>
                                        ${data.loyalty ?? '?'}
                                    </div>
                                    <div>
                                        <b>${locales.war_win_rate}: </b>
                                        %${data.warWinRate ?? '?'}
                                    </div>
                                    <div class="flex-col">
                                        <b>${locales.tribute_zones}: </b>
                                        <ul class="list-disc ml-[0.8vw]">
                                            ${zoneList}
                                        </ul>
                                    </div>
                                    <div class="flex-col">
                                        <b>${locales.current_enemies}: </b>
                                        <ul class="list-disc ml-[0.8vw]">
                                            ${enemyList}
                                        </ul>
                                    </div>
                                    <div class="min-w-[250px] flex justify-end gap-2 pt-1">
                                        ${canDeclareWar(data.name) ? `<button class="bg-red-400 text-black font-bold py-1 px-2 text-base hover:bg-red-600" onclick="declareWar('${data.name}');closePopup();">${locales.declare_war}</button>` : ''}
                                        <button class="bg-gray-400 text-black font-bold py-1 px-2 text-base hover:bg-gray-600" onclick="setOnGPS(${center.lng}, ${center.lat});closePopup();">${locales.set_on_gps}</button>
                                    </div>
                                </div>
                            </div>
                        `;

						const popup = L.popup({ closeOnEscapeKey: false, autoPan: true, autoPanPadding: L.point(15, 15) })
							.setContent(popupContent)
							.setLatLng(center)
							.openOn(map);
						popup.on('popupclose', function () {
							map.removeLayer(popup);
						});
					}, 100);
				};

				polygon.on('click', clickHandler);
				marker.on('click', clickHandler);

				return { ...data, polygon, marker };
			})
		);

		$GANGS = gangs;

		const tributes = await Promise.all(
			$TRIBUTE_ZONES.map(async (data) => {
				const latlngs = convertPointsToLatlng(data.territory);
				let owner = { label: locales.unclaimed, color: '#FFFFFF' };
				if (data.owner) owner = $GANGS.find((gangData) => gangData.name == data.owner);

				const polygon = L.polygon(latlngs, { color: owner.color, fillOpacity: 0.7, weight: 1 }).addTo(map);
				const center = polygon.getCenter();
				const icon = L.icon({
					iconUrl: './blips/money_blip.png',
					iconSize: [12, 12],
				});
				const marker = L.marker(center, { icon: icon }).addTo(map);

				const clickHandler = () => {
					map.flyTo(center, 6, {
						animate: true,
						duration: 1.5,
					});

					setTimeout(() => {
						const popupContent = `
                            <div class="w-[13vw] flex flex-wrap justify-center gap-2 bg-primary">
                                <img class="w-auto border-gray-700 border" src="tributes/${data.name}.png" alt="" />
                                <div class="text-2xl font-bold text-white break-words ...">${data.label}</div>
                                <div class="w-full flex flex-col gap-1 text-lg">
                                    <div>
                                        <b>${locales.current_owner}: </b>
                                        ${owner.label}
                                    </div>
                                    <div>
                                        <b>${locales.payment_amount_per_hours.format($CONFIG.tributePaymentInterval)}: </b>
                                        ${locales.$}${data.paymentAmount}
                                    </div>
                                    ${
										data.captureTimerLabel
											? `
                                        <div>
                                            <b>${locales.time_of_capture}: </b>
                                            ${data.captureTimerLabel}
                                        </div>
                                            `
											: ''
									}
                                </div>
                                <div class="w-full flex justify-end gap-2 pt-1">
                                    <button class="bg-gray-400 text-black font-bold py-1 px-2 text-base hover:bg-gray-600" onclick="setOnGPS(${center.lng}, ${center.lat});closePopup();">${locales.set_on_gps}</button>
                                </div>
                            </div>
                        `;

						const popup = L.popup({ closeOnEscapeKey: false, autoPan: true, autoPanPadding: L.point(15, 15) })
							.setContent(popupContent)
							.setLatLng(center)
							.openOn(map);
						popup.on('popupclose', function () {
							map.removeLayer(popup);
						});
					}, 100);
				};

				polygon.on('click', clickHandler);
				marker.on('click', clickHandler);

				return { ...data, polygon, marker };
			})
		);

		$TRIBUTE_ZONES = tributes;

		const playerIcon = L.icon({
			iconUrl: './blips/player_blip.png',
			iconSize: [12, 12],
		});
		const playerMarker = L.marker([$PLAYER.coord.y, $PLAYER.coord.x], { icon: playerIcon, zIndexOffset: 10 }).addTo(map);
		playerMarker.on('click', () => map.setView([$PLAYER.coord.y, $PLAYER.coord.x], 6));

		// map.on('zoom', function () {
		// 	const zoom = map.getZoom();
		// 	const newSize = zoom * 3;

		// 	const _playerIcon = playerMarker.getIcon();
		// 	_playerIcon.options.iconSize = [newSize, newSize];
		// 	playerMarker.setIcon(_playerIcon);

		// 	[...$GANGS, ...$TRIBUTE_ZONES].forEach((data) => {
		// 		if (data.marker) {
		// 			const icon = data.marker.getIcon();
		// 			icon.options.iconSize = [newSize, newSize];
		// 			data.marker.setIcon(icon);
		// 		}
		// 	});
		// });

		const markerGroup = L.layerGroup([playerMarker, ...$GANGS.map((g) => g.marker), ...$TRIBUTE_ZONES.map((z) => z.marker)]);
		map.addLayer(markerGroup);

		map.on('zoom', function () {
			const zoom = map.getZoom();
			const newSize = zoom * 3;

			markerGroup.eachLayer((layer) => {
				if (layer instanceof L.Marker) {
					const icon = layer.getIcon();
					if (icon.options.iconSize[0] !== newSize || icon.options.iconSize[1] !== newSize) {
						icon.options.iconSize = [newSize, newSize];
						layer.setIcon(icon);
					}
				}
			});
		});
	});
</script>

<div class="w-[53vw] h-[95vh] border-2 border-gray-400 rounded" bind:this={mapElement}>
	{#if map}
		<slot />
	{/if}
</div>
