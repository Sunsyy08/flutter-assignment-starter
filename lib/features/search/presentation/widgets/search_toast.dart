import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../theme/app_assets.dart';
import '../../../../theme/app_theme.dart';
import '../layout/search_layout_spec.dart';

class SearchToast extends StatelessWidget {
  const SearchToast({required this.layout, required this.message, super.key});

  final SearchLayoutSpec layout;
  final String message;

  @override
  Widget build(BuildContext context) {
    // ClipRRect로 둥근 모서리 적용 후 BackdropFilter로 블러 효과
    // 피그마 기준: 블러 배경 + 보라색 테두리 + 그림자
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: SearchLayoutSpec.toastHeight,
          padding: EdgeInsets.symmetric(
            horizontal: 16 * layout.horizontalScale,
          ),
          decoration: BoxDecoration(
            color: AppDerivedColors.searchToastBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppDerivedColors.searchToastBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppDerivedColors.searchToastGlow,
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              // 하트 + 체크 아이콘 조합 (20x20 슬롯)
              SizedBox(
                key: const Key('search-toast-favorite-icon'),
                width: 20,
                height: 20,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 하트 아이콘
                    AppAssetSlotIcon(
                      assetPath: AppAssets.favoriteHeart,
                      slotWidth: 20,
                      slotHeight: 20,
                      assetWidth: AppAssetSizes.favoriteHeart.width,
                      assetHeight: AppAssetSizes.favoriteHeart.height,
                      color: AppColors.mainAndAccent.up_f93f62,
                    ),
                    // 체크 아이콘 (하트 오른쪽 아래)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: AppAssetSlotIcon(
                        key: const Key('search-toast-check-icon'),
                        assetPath: AppAssets.toastCheck,
                        slotWidth: 10,
                        slotHeight: 10,
                        assetWidth: AppAssetSizes.toastCheck.width,
                        assetHeight: AppAssetSizes.toastCheck.height,
                        color: AppColors.mainAndAccent.up_f93f62,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.searchToast,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}