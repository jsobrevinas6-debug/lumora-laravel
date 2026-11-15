<?php

namespace App\Support;

final class CategoryCatalog
{
    /**
     * Leaf categories are the only selectable values stored in products.category.
     * Keeping the stored value as a slug makes seller and buyer filtering reliable.
     */
    public static function tree(): array
    {
        return [
            [
                'label' => "Men",
                'slug' => 'men',
                'children' => [
                    ['label' => 'Clothing', 'slug' => 'mens-clothing'],
                    ['label' => 'Shoes', 'slug' => 'mens-shoes'],
                    ['label' => 'Accessories', 'slug' => 'mens-accessories'],
                    [
                        'label' => 'Grooming',
                        'slug' => 'mens-grooming',
                        'children' => [
                            ['label' => 'Shavers & Trimmers', 'slug' => 'shavers-trimmers'],
                            ['label' => 'Hair Care', 'slug' => 'mens-hair-care'],
                            ['label' => 'Skincare', 'slug' => 'mens-skincare'],
                        ],
                    ],
                ],
            ],
            [
                'label' => "Women",
                'slug' => 'women',
                'children' => [
                    ['label' => 'Clothing', 'slug' => 'womens-clothing'],
                    ['label' => 'Shoes', 'slug' => 'womens-shoes'],
                    ['label' => 'Bags', 'slug' => 'womens-bags'],
                    ['label' => 'Accessories', 'slug' => 'womens-accessories'],
                    ['label' => 'Beauty', 'slug' => 'womens-beauty'],
                ],
            ],
            [
                'label' => 'Electronics',
                'slug' => 'electronics',
                'children' => [
                    [
                        'label' => 'Phones & Tablets',
                        'slug' => 'phones-tablets',
                        'children' => [
                            [
                                'label' => 'Smartphones',
                                'slug' => 'smartphones',
                                'children' => [
                                    ['label' => 'Apple', 'slug' => 'apple'],
                                    ['label' => 'Samsung', 'slug' => 'samsung'],
                                    ['label' => 'Xiaomi', 'slug' => 'xiaomi'],
                                    ['label' => 'OPPO', 'slug' => 'oppo'],
                                ],
                            ],
                            ['label' => 'Tablets', 'slug' => 'tablets'],
                            ['label' => 'Accessories', 'slug' => 'electronics-accessories'],
                        ],
                    ],
                    ['label' => 'Computers', 'slug' => 'computers'],
                    ['label' => 'Appliances', 'slug' => 'appliances'],
                    ['label' => 'Audio', 'slug' => 'audio'],
                    ['label' => 'Cameras', 'slug' => 'cameras'],
                ],
            ],
            [
                'label' => 'Home & Living',
                'slug' => 'home-living',
                'children' => [
                    ['label' => 'Furniture', 'slug' => 'furniture'],
                    ['label' => 'Kitchen', 'slug' => 'kitchen'],
                    ['label' => 'Home', 'slug' => 'home'],
                    ['label' => 'Home Decor', 'slug' => 'home-decor'],
                ],
            ],
            [
                'label' => 'Sports & Outdoors',
                'slug' => 'sports-outdoors',
                'children' => [
                    ['label' => 'Running', 'slug' => 'running'],
                    ['label' => 'Basketball', 'slug' => 'basketball'],
                    ['label' => 'Football', 'slug' => 'football'],
                    ['label' => 'Hiking', 'slug' => 'hiking'],
                    ['label' => 'Fitness', 'slug' => 'fitness'],
                ],
            ],
            [
                'label' => 'Beauty & Personal Care',
                'slug' => 'beauty-personal-care',
                'children' => [
                    ['label' => 'Skincare', 'slug' => 'skincare'],
                    ['label' => 'Makeup', 'slug' => 'makeup'],
                    ['label' => 'Hair Care', 'slug' => 'hair-care'],
                    ['label' => 'Personal Care', 'slug' => 'personal-care'],
                    ['label' => 'Bath Essentials', 'slug' => 'bath-essentials'],
                    ['label' => 'Kid Bath & Baby Care', 'slug' => 'kid-bath-baby-care'],
                    ['label' => 'Fragrance', 'slug' => 'fragrance'],
                ],
            ],
        ];
    }

    public static function leaves(): array
    {
        $leaves = [];
        self::walk(self::tree(), $leaves);
        return $leaves;
    }

    public static function slugs(): array
    {
        return array_column(self::leaves(), 'slug');
    }

    public static function label(string $slug): string
    {
        foreach (self::leaves() as $category) {
            if ($category['slug'] === $slug) {
                return $category['label'];
            }
        }

        return collect(explode('-', $slug))
            ->map(fn (string $word) => ucfirst($word))
            ->join(' ');
    }

    private static function walk(array $nodes, array &$leaves): void
    {
        foreach ($nodes as $node) {
            if (!empty($node['children'])) {
                self::walk($node['children'], $leaves);
            } else {
                $leaves[] = [
                    'label' => $node['label'],
                    'slug' => $node['slug'],
                ];
            }
        }
    }
}

