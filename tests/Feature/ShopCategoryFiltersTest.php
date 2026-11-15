<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Product;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\TestCase;

class ShopCategoryFiltersTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->withoutVite();
    }

    public function test_parent_and_leaf_categories_filter_products_and_show_aggregate_counts(): void
    {
        $seller = User::factory()->create(['role' => 'seller', 'shop_name' => 'Rose Studio']);
        $this->product($seller, ['name' => 'Men coat', 'category' => 'mens-clothing']);
        $this->product($seller, ['name' => 'Men shoes', 'category' => 'mens-shoes']);
        $this->product($seller, ['name' => 'Beauty item', 'category' => 'makeup']);

        $this->get('/shop?category=men')->assertOk()->assertSee('Men coat')->assertSee('Men shoes')->assertDontSee('Beauty item')->assertSee('2', false);
        $this->get('/shop?category=mens-clothing')->assertOk()->assertSee('Men coat')->assertDontSee('Men shoes');
        $this->get('/shop?category=men&min_price=0')->assertSee('2 products');
    }

    public function test_root_landing_still_uses_the_existing_landing_view(): void
    {
        $this->get('/')->assertOk()->assertSee('Timeless Elegance')->assertSee('flowMenuDrawer');
    }

    public function test_shared_header_markup_matches_on_home_shop_and_parent_category(): void
    {
        $this->actingAs(User::factory()->create(['role' => 'buyer']));
        $headers = [];
        foreach (['/', '/shop', '/shop?category=men'] as $path) {
            $response = $this->get($path)->assertOk();
            preg_match('/<header class="topbar">.*?<\/header>/s', $response->getContent(), $match);
            $this->assertNotEmpty($match, 'Expected the shared storefront header on '.$path);
            $headers[] = $match[0];
        }
        $this->assertSame($headers[0], $headers[1]);
        $this->assertSame($headers[1], $headers[2]);
        $this->assertStringContainsString('class="account-text"', $headers[0]);
        $this->assertStringNotContainsString('buyer-badge', $headers[0]);
    }

    public function test_filters_combine_and_invalid_price_input_is_rejected(): void
    {
        $seller = User::factory()->create(['role' => 'seller']);
        $rated = $this->product($seller, ['name' => 'Rated sale', 'price' => 800, 'discount_percent' => 20, 'stock' => 3]);
        $this->review($rated, 5);
        $mixed = $this->product($seller, ['name' => 'Mixed rating', 'price' => 700, 'discount_percent' => 10, 'stock' => 2]);
        $this->review($mixed, 5);
        $this->review($mixed, 2);
        $this->product($seller, ['name' => 'No stock sale', 'price' => 800, 'discount_percent' => 20, 'stock' => 0]);
        $this->product($seller, ['name' => 'Cheap regular', 'price' => 300]);

        $this->get('/shop?min_price=500&max_price=1000&on_sale=1&in_stock=1')
            ->assertOk()->assertSee('Rated sale')->assertDontSee('No stock sale')->assertDontSee('Cheap regular');
        $this->get('/shop?rating=4')->assertOk()->assertSee('Rated sale')->assertDontSee('Mixed rating')->assertDontSee('No stock sale');
        $this->get('/shop?min_price=1000&max_price=500')->assertRedirect()->assertSessionHasErrors('min_price');
        $this->get('/shop?min_price=abc')->assertSessionHasErrors('min_price');
    }

    public function test_sorts_preserve_the_expected_order_and_pagination_query_string(): void
    {
        $seller = User::factory()->create(['role' => 'seller']);
        $cheap = $this->product($seller, ['name' => 'A cheap', 'price' => 10, 'sales_count' => 1, 'created_at' => now()->subDay()]);
        $expensive = $this->product($seller, ['name' => 'B expensive', 'price' => 90, 'sales_count' => 9]);
        $topRated = $this->product($seller, ['name' => 'C rated', 'price' => 50, 'sales_count' => 3]);
        $reviewer = User::factory()->create(['role' => 'buyer']);
        DB::table('product_reviews')->insert(['user_id'=>$reviewer->id,'product_id'=>$topRated,'rating'=>5,'review'=>'great','created_at'=>now(),'updated_at'=>now()]);

        $this->get('/shop?sort=price_asc')->assertSeeInOrder(['A cheap','C rated','B expensive']);
        $this->get('/shop?sort=price_desc')->assertSeeInOrder(['B expensive','C rated','A cheap']);
        $this->get('/shop?sort=top_sales')->assertSeeInOrder(['B expensive','C rated','A cheap']);
        $this->get('/shop?sort=top_rated')->assertSeeInOrder(['C rated','B expensive']);
        $this->get('/shop?sort=popular')->assertSeeInOrder(['C rated','B expensive']);
        for ($i=1;$i<=13;$i++) $this->product($seller,['name'=>'Page product '.$i,'discount_percent'=>10,'created_at'=>now()->addSeconds($i)]);
        $response=$this->get('/shop?sort=newest&on_sale=1');
        $response->assertOk()->assertSee('Page product 13')->assertDontSee('Page product 1</div>')->assertSee('page=2')->assertSee('sort=newest')->assertSee('on_sale=1');
    }

    public function test_only_approved_active_products_are_listed_and_sold_out_has_no_quick_add(): void
    {
        $seller = User::factory()->create(['role' => 'seller']);
        $this->product($seller, ['name'=>'Visible sold out','stock'=>0]);
        $this->product($seller, ['name'=>'Pending hidden','approval_status'=>'pending']);
        $this->product($seller, ['name'=>'Inactive hidden','status'=>'inactive']);
        $this->get('/shop')->assertOk()->assertSee('Visible sold out')->assertDontSee('Pending hidden')->assertDontSee('Inactive hidden')->assertDontSee('Add Visible sold out to cart');
    }

    public function test_authenticated_buyer_can_toggle_a_wishlist_item(): void
    {
        $buyer = User::factory()->create(['role' => 'buyer']);
        $seller = User::factory()->create(['role' => 'seller']);
        $product = $this->product($seller);

        $this->actingAs($buyer)->postJson(route('buyer.wishlist.toggle', $product))
            ->assertOk()->assertJsonPath('saved', true);
        $this->assertDatabaseHas('saved_products', ['user_id' => $buyer->id, 'product_id' => $product]);
        $this->postJson(route('buyer.wishlist.toggle', $product))->assertOk()->assertJsonPath('saved', false);
        $this->assertDatabaseMissing('saved_products', ['user_id' => $buyer->id, 'product_id' => $product]);
    }

    private function product(User $seller, array $overrides=[]): int
    {
        return (int) DB::table('products')->insertGetId(array_merge([
            'seller_id'=>$seller->id,'name'=>'Fixture product','sku'=>'SKU-'.Str::upper(Str::random(8)),
            'category'=>'mens-clothing','description'=>'Test description','price'=>200,'discount_percent'=>0,
            'sales_count'=>0,'rating'=>0,'stock'=>5,'image'=>'products/example.jpg','status'=>'active',
            'approval_status'=>'approved','created_at'=>now(),'updated_at'=>now(),
        ],$overrides));
    }

    private function review(int $productId, int $rating): void
    {
        $reviewer=User::factory()->create(['role'=>'buyer']);
        DB::table('product_reviews')->insert(['user_id'=>$reviewer->id,'product_id'=>$productId,'rating'=>$rating,'review'=>'test','created_at'=>now(),'updated_at'=>now()]);
    }
}
