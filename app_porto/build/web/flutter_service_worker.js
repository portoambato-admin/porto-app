'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "99184231187c2ae7ecec2b50b4587555",
"assets/AssetManifest.bin.json": "6d9feee16b97f9dd33956cf91d65301b",
"assets/AssetManifest.json": "b9b4fb6195db73240779151da37f4526",
"assets/assets/fonts/MaterialIcons-Regular.ttf": "4e85bc9ebe07e0340c9c4fc2f6c38908",
"assets/assets/fonts/Roboto-Regular.ttf": "303c6d9e16168364d3bc5b7f766cfff4",
"assets/assets/icons/instagram.svg": "c9b542c91e8ef706f135ea9aea3a7fe1",
"assets/assets/icons/whatsapp.svg": "27695e0730a7fbf593ffbf5d8749024b",
"assets/assets/icons/youtube.svg": "edd7a059874cdb87c0c0d9250691425f",
"assets/assets/img/banner.webp": "06405bccd6e2b7c0e2a5922b262ebba9",
"assets/assets/img/categorias/sub10.webp": "5df7909e2a8d972d08ee2b768f006b16",
"assets/assets/img/categorias/sub12.webp": "0dcf7f03dd8bce2a81e1e425e8db2f2e",
"assets/assets/img/categorias/sub4.webp": "7141b23b5b5471f7dbd47ff06bd12273",
"assets/assets/img/categorias/sub6.webp": "2ad5030bb0db9f4a8ee7d286143e1d06",
"assets/assets/img/categorias/sub8.webp": "d688e7f566e2c074cba5a063f1c0db75",
"assets/assets/img/conocenos/instalaciones/ins_1.webp": "a17fffb2819be873abe7a75510bd1362",
"assets/assets/img/conocenos/instalaciones/ins_2.jpg": "109a9cfb008fa05daee92d17f284e5c9",
"assets/assets/img/conocenos/instalaciones/ins_3.webp": "45b2ea57211f7192ab4b77f79e95e109",
"assets/assets/img/conocenos/instalaciones/ins_4.webp": "5911e4d352290bf735752e6c4980d7cc",
"assets/assets/img/eventos/barranquilla2024/2024_1_thumb.webp": "1014e14d86d6b2ebfc9eb28deb1822dc",
"assets/assets/img/eventos/barranquilla2024/2024_2_thumb.webp": "409f95dcccde10dde70d4a2f88ed746e",
"assets/assets/img/eventos/barranquilla2024/2024_3_thumb.webp": "7c727b32f571fd971eef028a836c8267",
"assets/assets/img/eventos/medellin2023/2023_1_thumb.webp": "0a3b5658d0ef6a7c0f83ebadb2d53bcd",
"assets/assets/img/eventos/medellin2023/2023_2_thumb.webp": "6d2502c4cf5d39d85cb5c751702485eb",
"assets/assets/img/eventos/medellin2023/2023_3_thumb.webp": "3947ebf9530dfc6cdd723a6333eaa78f",
"assets/assets/img/eventos/panama2025/2025_1_thumb.webp": "f386292cd6dd54bab9debec7dec16f53",
"assets/assets/img/eventos/panama2025/2025_2_thumb.webp": "00c8d8aaa5cdcc8305f4666ee494758d",
"assets/assets/img/eventos/panama2025/2025_3_thumb.webp": "8ff4d67fc5f286989c4a0d8708f61041",
"assets/assets/img/eventos/panama2025/2025_4_thumb.webp": "c654f0cbfa239830b0851ccf9425f21f",
"assets/assets/img/eventos/panama2025/2025_5_thumb.webp": "b7e9865fc001fc1d1aaf1b237c22f807",
"assets/assets/img/eventos/panama2025/2025_6_thumb.webp": "9c8036f165923fae355efb1e885c39b4",
"assets/assets/img/eventos/panama2025/2025_7_thumb.webp": "5bb9a7bd2777255e417fe55fc322f78e",
"assets/assets/img/eventosWebp/2023_3.webp": "c0a09ddc2fb2016d645257f8a0a560c4",
"assets/assets/img/eventosWebp/2024_1.webp": "202c233e6a77cf06733c3d042f60c420",
"assets/assets/img/google.png": "ca2f7db280e9c773e341589a81c15082",
"assets/assets/img/profes/gerente.jpg": "151a7ab92759002879dacaede4919982",
"assets/assets/img/profes/p1.webp": "710e980ec8531ea2323edeb106b25c6d",
"assets/assets/img/profes/p2.webp": "7a0964b9651fa69caface38b767b76b0",
"assets/assets/img/profes/p3.webp": "dc86bb365e7d5e71819fc46d4166b793",
"assets/assets/img/profes/p4.webp": "f2169aeae16afa157f6ebec7a87b42b9",
"assets/assets/img/sponsors/agradecimiento.webp": "bb474ad0b721fc5f692cbd667bdf8241",
"assets/assets/img/sponsors/Imagen%2520de%2520WhatsApp%25202025-09-11%2520a%2520las%252019.28.17_182d672a.jpg": "84d3df18ace844a23513c119e78af1bd",
"assets/assets/img/sponsors/minegocio.webp": "0bd08e75f19cffe0a45a7b5a30fe2bdb",
"assets/assets/img/sponsors/moderna.webp": "08755db67b3530f3d8655283ae570ebb",
"assets/assets/img/sponsors/mundi.webp": "789d55fdca779877cd76c8583515e988",
"assets/assets/img/sponsors/opalo.webp": "63367f5846e0bbb5fcdf1220ce53042e",
"assets/assets/img/sponsors/pass.webp": "23146a42631ef81be71ceadc7d7c2d6f",
"assets/assets/img/sponsors/sanfra.webp": "f983d98a46554d8aaaa15232dbe42f37",
"assets/assets/img/sponsors/tarco.webp": "87f2b30ba8ad46e2f5398138149ea734",
"assets/assets/img/sponsors/togo.webp": "f0df4ac30f8c79b5bf2b779b8f5ba6eb",
"assets/assets/img/sponsors/waikiki.webp": "912e77e7e8b5d497ce6fd85d9996bcec",
"assets/assets/img/thumbs/banner_thumb.webp": "d1feb88394081faff5e374ebfd5561fd",
"assets/assets/img/thumbs/escudocris_thumb.webp": "5e362550137519d9971feddbefa97f1a",
"assets/assets/img/thumbs/escudo_thumb.webp": "34d90cdf1705301aa620aa2fbd0c91a0",
"assets/assets/img/thumbs/hero_thumb.webp": "55cd6d84cf6c705ee4b034c5fa3dfafc",
"assets/assets/img/thumbs/logo_thumb.webp": "a218422c9314820234052172c4c8a586",
"assets/assets/img/thumbs/main_thumb.webp": "e0454173aad71c6c9377b672f09fb05e",
"assets/assets/img/thumbs/partido_thumb.webp": "3d59703c8244fc0b801d2e3ff1dc9cb8",
"assets/assets/img/tienda/bolozap.webp": "682e5a1afac250607c11f69b46c1460a",
"assets/assets/img/tienda/bolsoviaje.webp": "a517d084dec8a11645335d62a07bf978",
"assets/assets/img/tienda/buzo.webp": "9b69d691078eb6b8f7467975f6ea124c",
"assets/assets/img/tienda/canilleras.webp": "66fad055f1cf43c6b4c9d84e90e032af",
"assets/assets/img/tienda/chompa.webp": "384fa9368557ae29c18c60a79bb70bc4",
"assets/assets/img/tienda/medias.webp": "9a9571791a1c1badc89a5a946554d329",
"assets/assets/img/tienda/medias2.webp": "2ff5b6ffc9a7be641f00ec1ad72a6249",
"assets/assets/img/tienda/pechera.webp": "a10ec5c01656100dd317cf9b169b0fe2",
"assets/assets/img/tienda/polo.webp": "5419885ecadf02c16eff75f3076226a1",
"assets/assets/img/tienda/stickets.webp": "71b2200690719795fb3e41d082aaa806",
"assets/assets/img/tienda/uniforme1.webp": "9d42dcd23d5a0f6c60d1df14b06ea356",
"assets/assets/img/tienda/uniforme2.webp": "7a36df1cabb350c91c896cfeb0494633",
"assets/assets/img/webp/escudo.webp": "2b8beeb41e279c9a269fa5022a8501fe",
"assets/assets/img/webp/escudocris.webp": "fbc4025663b152c389b4fbef0cb3298e",
"assets/assets/img/webp/hero.webp": "e81dc7b4d99424a474771ad747e938b5",
"assets/assets/img/webp/logo.webp": "fd7e0aa634075f5e6f691faa66925f66",
"assets/assets/img/webp/main.webp": "20e939c69ebfab2c73b4dc78e6b27b34",
"assets/assets/img/webp/partido.webp": "024b1f68165933d0c8096a3b8d96c0de",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "b508192d19104e6a2b1e5a52a0b93aca",
"assets/NOTICES": "6cf4c58e840ca75de594ad3220e16e80",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/packages/youtube_player_iframe/assets/player.html": "663ba81294a9f52b1afe96815bb6ecf9",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"favicon.png": "cd0829ede26d38fa2d0cb2ba8178a33e",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"flutter_bootstrap.js": "49abc03ba4c26a285e1669c59ae8bb5d",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "c545ea13d85811ddfe79506ddca06904",
"/": "c545ea13d85811ddfe79506ddca06904",
"main.dart.js": "ba0dbbd625d31e8e5c6ec06d7f79523e",
"main.dart.js_1.part.js": "a9adb47e256272830d2e366ca0e9acc3",
"main.dart.js_2.part.js": "ddf838cf359f352c53e1e22646b4255e",
"main.dart.js_3.part.js": "202999c7aa4a00c6f4faf11c0fa39d0c",
"main.dart.js_4.part.js": "d382b1bbcaec679237a0f5f6bc7c4be7",
"main.dart.js_5.part.js": "18e130ce04d881894756c111844edfe6",
"main.dart.js_6.part.js": "fa1a3c3a1cc9b8e229d73e63da3cee59",
"main.dart.js_7.part.js": "389f9dc70e4e1173012a2492854d3f08",
"manifest.json": "28d4c0b0f4d9ef3b866fee1a4aa7c0db",
"version.json": "efa990abf78aa2abbb90064eec92e8f9"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
