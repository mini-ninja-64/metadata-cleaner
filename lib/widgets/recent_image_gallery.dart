import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class RenderedAsset {
  final AssetEntity assetEntity;
  final Uint8List thumbnailData;
  RenderedAsset(this.assetEntity, this.thumbnailData);
}

class RecentImageGallery extends StatefulWidget {
  final Function(File)? onImageSelect;

  const RecentImageGallery({super.key, this.onImageSelect});

  @override
  State<RecentImageGallery> createState() => _RecentImageGallery();
}

class _RecentImageGallery extends State<RecentImageGallery> {
  static const pageSize = 42;

  bool loadingImages = false;
  bool recentLibraryFound = false;
  AssetPathEntity?
      recentAlbum; // not a late variable as will be initialised by a future

  int currentPage = 0;
  List<RenderedAsset> assetsWithThumbnails = [];

  @override
  void initState() {
    super.initState();
    _loadInitialImageBatch();
  }

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.all(10);
    if (!recentLibraryFound) {
      return Container(
          padding: padding, child: const Text("no images found :c"));
    }

    return GridView.builder(
        padding: padding,
        itemCount: assetsWithThumbnails.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisSpacing: 10, mainAxisSpacing: 10, crossAxisCount: 3),
        itemBuilder: (context, index) {
          var decoration = const BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          );

          // TODO: infinite loading, should optimize into slices first
          if (index >= assetsWithThumbnails.length - (pageSize ~/ 2)) {
            _loadMoreRecentImages();
          }

          var currentAsset = assetsWithThumbnails[index];

          return ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            clipBehavior: Clip.antiAlias,
            child: Material(
                child: Ink.image(
              image: MemoryImage(currentAsset.thumbnailData),
              fit: BoxFit.cover,
              child: InkWell(
                onTap: () async {
                  // TODO: set state to disallow selection

                  var assetFile = await currentAsset.assetEntity.file;
                  if (assetFile == null) {
                    throw const FileSystemException("File could not be loaded");
                  }
                  widget.onImageSelect?.call(assetFile);
                },
              ),
            )),
          );
        });
  }

  // TODO: don't like the locking approach here, it should only have the opportunity to be called once ideally
  // TODO: does not support new images being added since initial render, need to think how to approach
  // TODO: does this image fetching & management belong in a service? probably
  // TODO: memory keeps growing probably wanna have it in chunks so if we get 1000 images deep we can delete the first 500 or w/e then reload them as necessary, this depends on memory footprint, so would need to profile
  Future<void> _loadMoreRecentImages() async {
    if (recentAlbum == null) return;
    if (loadingImages) return;
    loadingImages = true;
    var albumItems =
        await recentAlbum!.getAssetListPaged(page: currentPage, size: pageSize);

    // TODO: early mime type filtering
    ///  * Android: `MediaStore.MediaColumns.MIME_TYPE`.
    ///  https://developer.apple.com/documentation/uniformtypeidentifiers/uttype/3551523-jpeg
    ///
    ///  * iOS/macOS: MIME type from `PHAssetResource.uniformTypeIdentifier`.
    ///  https://developer.apple.com/documentation/uniformtypeidentifiers/uttype/3551551-png
    ///  May have to bridge to IOS with a native plugin to test mime-type properly
    var futureAssets = albumItems
        // .where((asset) => validTypes.contains(await asset.mimeTypeAsync))
        .map((asset) async {
      var thumbnail =
          await asset.thumbnailDataWithSize(const ThumbnailSize.square(200));

      if (thumbnail == null) return null;
      return RenderedAsset(asset, thumbnail);
    });
    var renderedAssets = (await Future.wait(futureAssets))
        .where((element) => element != null)
        .map((e) => e!);
    //
    // await Future.delayed(const Duration(seconds: 5));

    setState(() {
      assetsWithThumbnails.addAll(renderedAssets);
    });

    currentPage++;
    loadingImages = false;
  }

  Future<void> _loadRecentAlbum() async {
    await PhotoManager.requestPermissionExtend();
    var albums = await PhotoManager.getAssetPathList(
        type: RequestType.image, hasAll: true);
    if (albums.isEmpty) return;

    var foundAlbum = albums[0];

    setState(() {
      recentAlbum = foundAlbum;
      recentLibraryFound = true;
    });
  }

  Future<void> _loadInitialImageBatch() async {
    await _loadRecentAlbum();
    await _loadMoreRecentImages();
  }
}
