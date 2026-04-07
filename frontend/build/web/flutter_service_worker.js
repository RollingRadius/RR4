'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"32.png": "0734688002f2128ead899d4ad555c7ae",
"assets/assest/icons/100.png": "6695502933ae1d7eca18af1dafed4835",
"assets/assest/icons/102.png": "cb9c8a9515031a784099372627194670",
"assets/assest/icons/1024.png": "1ab24e8c7084d370253c5d4618884139",
"assets/assest/icons/114.png": "35b3ccf7a306ff93498e42736d678fe0",
"assets/assest/icons/120.png": "c34e63fc8c2ed7a68e059d40fc9bf639",
"assets/assest/icons/128.png": "5f6720d0f9324a2045c36ae4979aac21",
"assets/assest/icons/144.png": "bda8e523199a4b497f08d31fe4ff5b45",
"assets/assest/icons/152.png": "869fe15064a2c3f843d75352a06421f0",
"assets/assest/icons/16.png": "04867a9525130f00971bf65277bf69c0",
"assets/assest/icons/167.png": "d694566b3e52a80ab94595fee8db9fe0",
"assets/assest/icons/172.png": "273ea424d776a62be6d8684826ebe6ee",
"assets/assest/icons/180.png": "b602a371b937e35522a512b9d133b340",
"assets/assest/icons/196.png": "0344ffcb39dbe1ab1f43a3e29cc2eabc",
"assets/assest/icons/20.png": "8cbea05fbc6b2ff077fa35ff8186282d",
"assets/assest/icons/216.png": "bb35d21eb0e0e7a41c6c962a27b4c37b",
"assets/assest/icons/256.png": "2310795010d8d48d20d2c8c05cd11ed7",
"assets/assest/icons/29.png": "d67439e1504c3e8b62c39fce13c7f1d4",
"assets/assest/icons/40.png": "43c3ba2ff3b2d61d8ad68a6f521fd1d2",
"assets/assest/icons/48.png": "c9d12b1c48519f21c11baeae3290359a",
"assets/assest/icons/50.png": "400dcfe3370ce9406302842911228c8a",
"assets/assest/icons/55.png": "2eb863484cfdcc5c14dce77d12b9cdf1",
"assets/assest/icons/57.png": "771940b9aa04f3d3d9b3badc344ef501",
"assets/assest/icons/58.png": "2e4cee425e8e4188a84d312d3f4edef3",
"assets/assest/icons/60.png": "dc900fe38ad912d8f29757bd04ce9694",
"assets/assest/icons/64.png": "942d08e49da0f0da2c93af65650e3235",
"assets/assest/icons/66.png": "bd1bf1deacfa692061b6837efd355731",
"assets/assest/icons/72.png": "e8a5c33523195424f40f3ca5ec1df9aa",
"assets/assest/icons/76.png": "b076386f41a09497cad3c4a77e4f85df",
"assets/assest/icons/80.png": "cc69be02d84f0919b252dc3061e1b1dc",
"assets/assest/icons/87.png": "ce9174582f857d47c5d9351a781fb7c3",
"assets/assest/icons/88.png": "d9a6f3a2bf9807582cd145e58410d777",
"assets/assest/icons/92.png": "568a885ea0df64ee0bed1d8a22acc837",
"assets/assest/icons/appstore.png": "1ab24e8c7084d370253c5d4618884139",
"assets/assest/icons/Contents.json": "62476f31fa1c8e76733c2e1fd6fd22e4",
"assets/assest/icons/icon.png": "bf6beb54415a3fd9ebdb3b0529627e4d",
"assets/assest/icons/playstore.png": "bf6beb54415a3fd9ebdb3b0529627e4d",
"assets/assest/images/app-logo-bgremoved.png": "ba5e1bf7bc7df4ad53aea6bfb77c2864",
"assets/assest/images/app-logo-with-name-small.png": "ba5f6f48c49cd018df06cb7ff3709f64",
"assets/assest/images/app-logo-with-name.png": "b9ab7c47f7a0e193a0cb85c6ffa3d04a",
"assets/assest/images/app-logo-with-space-around.png": "8cba64da278a269e038dc4439d9c251c",
"assets/assest/images/app-logo.png": "841ae489d45f435f328c38d5d4410f9c",
"assets/assest/images/blank-image.png": "179e9a477a95342a5b527b6ec605ba8d",
"assets/assest/images/blank-profile.png": "ff7e72a4f63fd0d2c17edebdd85989ae",
"assets/assest/images/clock.png": "c0091febbdfb94bacb488b00f4521d5a",
"assets/assest/images/containers-image.png": "e8427f9c76f3b9af26e6c9d6b16de8e1",
"assets/assest/images/light-1.png": "6c8ba31eab30d40b5ce914be52ca484e",
"assets/assest/images/light-2.png": "82bff49a319cf52b57967f67ead32154",
"assets/assest/images/login-screen-image.png": "5ad69c7624875b76c84eebb06806ff46",
"assets/assest/images/otp-verification-screen-image.png": "af558689fdcffd35185981e4838029a0",
"assets/assest/images/packages-screenshot.png": "a57db80bd2d5950cd546117d27317c56",
"assets/assest/images/truck-image.png": "f4aead7f0377dc9ffbb56aa6b1e4cc23",
"assets/assest/images/trucks-screenshot.png": "8d2483392db3aa866e47a99711d7bb27",
"assets/assest/images/username-login-background.png": "97bcdff34666d1b3e9ccbac7b1a58d95",
"assets/assest/images/welcome-screen-image.png": "fe71adcc8c40782af7b7555f0ffd44c1",
"assets/AssetManifest.bin": "260f40ce0c277735acfa929be008b8a6",
"assets/AssetManifest.bin.json": "12df2eafa8922a49f17bd8771f6b6168",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/fonts/MaterialIcons-Regular.otf": "1e7005d236a7300ce4ea8c4e8a061042",
"assets/NOTICES": "990f47b4af03dd361b834d13a20c0ef5",
"assets/packages/fluttertoast/assets/toastify.css": "a85675050054f179444bc5ad70ffc635",
"assets/packages/fluttertoast/assets/toastify.js": "56e2c9cedd97f10e7e5f1cebd85d53e3",
"assets/packages/flutter_map/lib/assets/flutter_map_logo.png": "208d63cc917af9713fc9572bd5c09362",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "b74cdf296b9ec1b05fd6beafaf88c29b",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "0c24373634c5f0c05931294e0c826e51",
"/": "0c24373634c5f0c05931294e0c826e51",
"load-provider/app.js": "4c56d952b21895b944cb24e213375dc1",
"load-provider/index.html": "0164d6936cd4e6caabfcd9ef190920e8",
"load-provider/styles.css": "5fb01624f12608c00df6663570e9eb98",
"main.dart.js": "ca32efb55efd4fad0eb0b2ee6b2a3edd",
"manifest.json": "a8dba868fe6762ff4a611eeba83dc07c",
"version.json": "cc762254ac8a02c01a3b5d4c4fc51499"};
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
