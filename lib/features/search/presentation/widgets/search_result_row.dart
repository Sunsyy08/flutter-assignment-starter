import 'package:flutter/material.dart';

import '../../../watchlist/domain/models/watchlist_models.dart';
import '../../../../theme/app_assets.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/services/search_text_utils.dart';
import '../layout/search_layout_spec.dart';

class SearchResultRow extends StatelessWidget {
  const SearchResultRow({
    required this.item,
    required this.query,
    required this.isSelected,
    required this.layout,
    required this.onTap,
    required this.onHeartTap,
    required this.onActionTap,
    super.key,
  });

  final StockSearchItem item;
  final String query;
  final bool isSelected;
  final SearchLayoutSpec layout;
  final VoidCallback onTap;
  final VoidCallback onHeartTap;
  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('search-result-${item.id}'),
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(
              key: Key('search-result-row-${item.id}'),
              height: SearchLayoutSpec.resultRowHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: layout.horizontalPadding,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SearchTextColumn(item: item, query: query),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      key: Key('search-heart-${item.id}'),
                      onTap: onHeartTap,
                      behavior: HitTestBehavior.opaque,
                      child: AppAssetSlotIcon(
                        key: Key('search-heart-icon-${item.id}'),
                        assetPath: AppAssets.favoriteHeart,
                        // Figma 기준 슬롯 44x44 (터치 영역), 아이콘은 16x13
                        slotWidth: 44,
                        slotHeight: 44,
                        assetWidth: AppAssetSizes.favoriteHeart.width,
                        assetHeight: AppAssetSizes.favoriteHeart.height,
                        color: item.isFavorite
                            ? AppColors.mainAndAccent.up_f93f62
                            : AppColors.darkTheme.c_424242,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isSelected) ...[
              Padding(
                padding: EdgeInsets.only(
                  left: layout.horizontalPadding,
                  right: layout.horizontalPadding,
                  bottom: 8,
                ),
                child: _SearchActionBar(
                  item: item,
                  onActionTap: onActionTap,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchActionBar extends StatelessWidget {
  const _SearchActionBar({
    required this.item,
    required this.onActionTap,
  });

  final StockSearchItem item;
  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('search-actions-${item.id}'),
      height: SearchLayoutSpec.expandedActionHeight,
      decoration: BoxDecoration(
        color: AppColors.bg.bg_2_212121,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border.border_5_3b3e53),
      ),
      child: Row(
        children: [
          // 뉴스 버튼
          Expanded(
            child: InkWell(
              key: const Key('search-action-뉴스'),
              onTap: () => onActionTap('뉴스'),
              child: Row(
                key: const Key('search-action-content-뉴스'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppAssetSlotIcon(
                    assetPath: AppAssets.actionNews,
                    slotWidth: 20,
                    slotHeight: 20,
                    assetWidth: AppAssetSizes.actionNews.width,
                    assetHeight: AppAssetSizes.actionNews.height,
                    color: AppColors.text.text_2_bdbdbd,
                  ),
                  const SizedBox(width: 4),
                  Text('뉴스', style: AppTypography.action),
                ],
              ),
            ),
          ),
          // 구분선
          Container(
            width: 1,
            height: 16,
            color: AppColors.border.border_5_3b3e53,
          ),
          // 종목토론 버튼
          Expanded(
            child: InkWell(
              key: const Key('search-action-종목토론'),
              onTap: () => onActionTap('종목토론'),
              child: Row(
                key: const Key('search-action-content-종목토론'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppAssetSlotIcon(
                    assetPath: AppAssets.actionDiscussion,
                    slotWidth: 20,
                    slotHeight: 20,
                    assetWidth: AppAssetSizes.actionDiscussion.width,
                    assetHeight: AppAssetSizes.actionDiscussion.height,
                    color: AppColors.text.text_2_bdbdbd,
                  ),
                  const SizedBox(width: 4),
                  Text('종목토론', style: AppTypography.action),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchTextColumn extends StatelessWidget {
  const _SearchTextColumn({required this.item, required this.query});

  final StockSearchItem item;
  final String query;

  @override
  Widget build(BuildContext context) {
    // splitSearchTextParts로 검색어 하이라이트 처리
    // 일치하는 부분은 보라색(point_b980ff)으로 강조
    final titleParts = splitSearchTextParts(item.name, query);
    final subtitleParts = splitSearchTextParts(
      buildSearchSubtitle(item),
      query,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: titleParts.map((part) {
              return TextSpan(
                text: part.text,
                style: AppTypography.searchName.copyWith(
                  // 하이라이트된 부분만 보라색 적용
                  color: part.isHighlighted
                      ? AppColors.point.jongmoksearch_b980ff
                      : AppColors.text.text_fafafa,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: subtitleParts.map((part) {
              return TextSpan(
                text: part.text,
                style: AppTypography.searchMeta.copyWith(
                  color: part.isHighlighted
                      ? AppColors.point.jongmoksearch_b980ff
                      : AppColors.text.text_3_9e9e9e,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}