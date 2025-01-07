import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';

import '../features/connections/service/base_connection_service.dart';
import '../features/connections/types/stremio/stremio_base.types.dart';
import '../features/connections/widget/base/render_stream_list.dart';
import '../features/connections/widget/stremio/stremio_item_viewer.dart';

class StremioItemPage extends StatefulWidget {
  final String type;
  final String id;
  final Meta? meta;
  final String? hero;
  final String connection;
  final BaseConnectionService? service;

  const StremioItemPage({
    super.key,
    required this.type,
    required this.id,
    required this.connection,
    this.hero,
    this.meta,
    this.service,
  });

  @override
  State<StremioItemPage> createState() => _StremioItemPageState();
}

class _StremioItemPageState extends State<StremioItemPage> {
  late Query<ConnectionRaw> query = Query(
    key: "item${widget.type}${widget.id}",
    onSuccess: (data) {},
    queryFn: () async {
      try {
        final result =
            await BaseConnectionService.connectionByIdRaw(widget.connection);
        final resultFirst = BaseConnectionService.connectionById(result);
        final value = await resultFirst.getItemById(
          Meta(
            type: widget.type,
            id: widget.id,
          ),
        );
        if (value == null) {
          return ConnectionRaw(
            connectionResponse: result,
            item: widget.meta as LibraryItem,
          );
        }

        return ConnectionRaw(
          item: value,
          connectionResponse: result,
        );
      } catch (e, stack) {
        print(e);
        print(stack);
        rethrow;
      }
    },
  );

  @override
  void initState() {
    super.initState();

    if (widget.meta?.progress != null || widget.meta?.nextEpisode != null) {
      Future.delayed(
        const Duration(milliseconds: 500),
        () {
          if (widget.meta != null && widget.service != null) {
            if (mounted) {
              final season = widget.meta?.nextSeason == null
                  ? ""
                  : "S${widget.meta?.nextSeason}";

              final episode = widget.meta?.nextEpisode == null
                  ? ""
                  : "E${widget.meta?.nextEpisode}";

              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Scaffold(
                    appBar: AppBar(
                      leading: IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close),
                      ),
                      title: Text(
                        "Streams  $season $episode".trim(),
                      ),
                    ),
                    body: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: RenderStreamList(
                          progress: widget.meta!.progress != null
                              ? widget.meta!.progress! * 100
                              : null,
                          service: widget.service!,
                          id: widget.meta as LibraryItem,
                          season: widget.meta?.nextSeason?.toString(),
                          episode: widget.meta?.nextEpisode?.toString(),
                          shouldPop: false,
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return QueryBuilder(
      query: query,
      builder: (context, state) {
        Meta? meta;

        if (state.status == QueryStatus.error) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(
                "Something went wrong ${state.error}",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (state.data?.connectionResponse != null &&
            state.data?.item is Meta) {
          meta = state.data?.item as Meta;
        }

        // if (DeviceDetector.isTV()) {
        //   return StremioItemViewerTV(
        //     hero: widget.hero,
        //     meta: meta ?? widget.meta,
        //     original: meta,
        //     library: widget.library,
        //     service: state.data == null
        //         ? null
        //         : BaseConnectionService.connectionById(
        //             state.data!.connectionResponse,
        //           ),
        //   );
        // }

        return StremioItemViewer(
          hero: widget.hero,
          meta: meta ?? widget.meta,
          original: meta,
          progress: widget.meta?.progress != null ? widget.meta!.progress : 0,
          service: state.data == null
              ? null
              : BaseConnectionService.connectionById(
                  state.data!.connectionResponse,
                ),
        );
      },
    );
  }
}

class ConnectionRaw {
  ConnectionResponse connectionResponse;
  LibraryItem item;

  ConnectionRaw({
    required this.connectionResponse,
    required this.item,
  });

  toJson() {
    return {
      "connectionResponse": connectionResponse.toJson(),
      "item": item.toJson(),
    };
  }
}
