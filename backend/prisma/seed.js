import slugify from 'slugify';
import { prisma } from '../src/lib/prisma.js';
import { hashPassword } from '../src/utils/password.js';

const categories = [
  { name: 'Clothing', description: 'Bespoke tailoring, silk dresses, and couture outerwear.' },
  { name: 'Home Accessories', description: 'Artisan tableware, crystal, and bespoke home styling.' },
  { name: 'Footwear', description: 'Handcrafted leather shoes, boots, and luxury sneakers.' },
  { name: 'Jewelry', description: 'Fine gemstone jewelry, heritage gold, and horology.' },
  { name: 'Bags', description: 'Artisanal leather handbags, totes, and luggage.' },
  { name: 'Décor', description: 'Architectural sculptures, fine ceramics, and limited editions.' },
];

async function main() {
  console.log('🌱 Starting Quiver Lux database seeding...');

  // 1. Seed Categories
  const categoryMap = new Map();
  for (const cat of categories) {
    const slug = slugify(cat.name, { lower: true, strict: true });
    const category = await prisma.category.upsert({
      where: { slug },
      update: {
        name: cat.name,
        description: cat.description,
        isActive: true,
      },
      create: {
        name: cat.name,
        slug,
        description: cat.description,
        isActive: true,
      },
    });
    categoryMap.set(cat.name, category);
  }
  console.log(`✅ Seeded ${categoryMap.size} marketplace categories.`);

  // 2. Seed Admin User
  const adminPasswordHash = await hashPassword('AdminPass123!');
  const admin = await prisma.user.upsert({
    where: { email: 'admin@quiverlux.com' },
    update: {
      firstName: 'Quiver',
      lastName: 'Admin',
      role: 'ADMIN',
      passwordHash: adminPasswordHash,
    },
    create: {
      email: 'admin@quiverlux.com',
      firstName: 'Quiver',
      lastName: 'Admin',
      role: 'ADMIN',
      passwordHash: adminPasswordHash,
      cart: { create: {} },
    },
  });
  console.log(`✅ Admin account configured: ${admin.email}`);

  // 3. Seed Verified Luxury Vendor
  const vendorPasswordHash = await hashPassword('VendorPass123!');
  const vendorUser = await prisma.user.upsert({
    where: { email: 'vendor@quiverlux.com' },
    update: {
      firstName: 'Aura',
      lastName: 'Atelier',
      role: 'VENDOR',
      phone: '+2348012345678',
      passwordHash: vendorPasswordHash,
    },
    create: {
      email: 'vendor@quiverlux.com',
      firstName: 'Aura',
      lastName: 'Atelier',
      role: 'VENDOR',
      phone: '+2348012345678',
      passwordHash: vendorPasswordHash,
      cart: { create: {} },
    },
  });

  const vendorSlug = 'aura-atelier';
  const vendor = await prisma.vendor.upsert({
    where: { userId: vendorUser.id },
    update: {
      storeName: 'Aura Atelier',
      brandName: 'Aura Atelier Luxury',
      slug: vendorSlug,
      description: 'Handcrafted luxury apparel and timeless bespoke lifestyle items from Lagos.',
      phone: '+2348012345678',
      businessAddress: '14 Victoria Island, Lagos, Nigeria',
      status: 'APPROVED',
      commissionRate: 10.00,
      rating: 4.9,
      storeLogo: 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=800',
      paystackBusinessName: 'Aura Atelier Luxury',
      paystackAccountName: 'Aura Atelier Ltd',
      paystackAccountNumber: '0123456789',
      paystackBankCode: '058',
      paystackSubaccountCode: 'SUB_aura_atelier_demo',
      paystackSetupComplete: true,
    },
    create: {
      userId: vendorUser.id,
      storeName: 'Aura Atelier',
      brandName: 'Aura Atelier Luxury',
      slug: vendorSlug,
      description: 'Handcrafted luxury apparel and timeless bespoke lifestyle items from Lagos.',
      phone: '+2348012345678',
      businessAddress: '14 Victoria Island, Lagos, Nigeria',
      status: 'APPROVED',
      commissionRate: 10.00,
      rating: 4.9,
      storeLogo: 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=800',
      paystackBusinessName: 'Aura Atelier Luxury',
      paystackAccountName: 'Aura Atelier Ltd',
      paystackAccountNumber: '0123456789',
      paystackBankCode: '058',
      paystackSubaccountCode: 'SUB_aura_atelier_demo',
      paystackSetupComplete: true,
    },
  });
  console.log(`✅ Approved vendor configured: ${vendor.brandName} (${vendorUser.email})`);

  // 4. Seed Test Customer
  const customerPasswordHash = await hashPassword('CustomerPass123!');
  const customer = await prisma.user.upsert({
    where: { email: 'customer@quiverlux.com' },
    update: {
      firstName: 'Sophia',
      lastName: 'Sterling',
      role: 'CUSTOMER',
      phone: '+2348098765432',
      passwordHash: customerPasswordHash,
    },
    create: {
      email: 'customer@quiverlux.com',
      firstName: 'Sophia',
      lastName: 'Sterling',
      role: 'CUSTOMER',
      phone: '+2348098765432',
      passwordHash: customerPasswordHash,
      cart: { create: {} },
    },
  });
  console.log(`✅ Customer account configured: ${customer.email}`);

  // 5. Seed Luxury Products
  const sampleProducts = [
    {
      name: 'Cashmere Trench Coat',
      category: 'Clothing',
      price: 245000,
      discountPrice: 215000,
      isLimitedOffer: true,
      stockQuantity: 12,
      description: 'Double-breasted Italian virgin wool and cashmere trench with horn buttons and storm collar.',
      image: 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=1000',
    },
    {
      name: 'Italian Leather Loafers',
      category: 'Footwear',
      price: 185000,
      discountPrice: null,
      isLimitedOffer: false,
      stockQuantity: 20,
      description: 'Hand-burnished calfskin loafers with Goodyear-welted leather soles and brushed brass bit.',
      image: 'https://images.unsplash.com/photo-1533867617858-e7b97e060509?w=1000',
    },
    {
      name: 'Gold Sovereign Chronograph',
      category: 'Jewelry',
      price: 650000,
      discountPrice: 590000,
      isLimitedOffer: true,
      stockQuantity: 5,
      description: '18k rose gold plated automatic chronograph watch with sapphire crystal face and alligator strap.',
      image: 'https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=1000',
    },
    {
      name: 'Calfskin Heritage Tote',
      category: 'Bags',
      price: 320000,
      discountPrice: null,
      isLimitedOffer: false,
      stockQuantity: 8,
      description: 'Full-grain structured leather tote bag featuring gold-plated hardware and suede lining.',
      image: 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=1000',
    },
    {
      name: 'Handcrafted Ceramic Amphora',
      category: 'Home Accessories',
      price: 95000,
      discountPrice: 80000,
      isLimitedOffer: true,
      stockQuantity: 15,
      description: 'Sculptural terracotta amphora vase with matte glaze finish, hand-thrown in limited editions.',
      image: 'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?w=1000',
    },
    {
      name: 'Sculptural Marble Bookends',
      category: 'Décor',
      price: 110000,
      discountPrice: null,
      isLimitedOffer: false,
      stockQuantity: 10,
      description: 'Carved solid Nero Marquina marble geometric bookends with felt base protection.',
      image: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1000',
    },
  ];

  for (const item of sampleProducts) {
    const productSlug = slugify(`${item.name} ${vendor.id.slice(0, 4)}`, { lower: true, strict: true });
    const category = categoryMap.get(item.category);
    if (!category) continue;

    const product = await prisma.product.upsert({
      where: { slug: productSlug },
      update: {
        name: item.name,
        description: item.description,
        price: item.price,
        discountPrice: item.discountPrice,
        stockQuantity: item.stockQuantity,
        isLimitedOffer: item.isLimitedOffer,
        isActive: true,
        approvalStatus: 'APPROVED',
        rating: 4.8,
      },
      create: {
        vendorId: vendor.id,
        categoryId: category.id,
        name: item.name,
        slug: productSlug,
        description: item.description,
        price: item.price,
        discountPrice: item.discountPrice,
        stockQuantity: item.stockQuantity,
        isLimitedOffer: item.isLimitedOffer,
        isActive: true,
        approvalStatus: 'APPROVED',
        rating: 4.8,
      },
    });

    const existingImage = await prisma.productImage.findFirst({
      where: { productId: product.id },
    });

    if (!existingImage) {
      await prisma.productImage.create({
        data: {
          productId: product.id,
          url: item.image,
          publicId: `seed-${product.id}`,
          isPrimary: true,
        },
      });
    }
  }
  console.log(`✅ Seeded ${sampleProducts.length} approved luxury products.`);
  console.log('🎉 Seeding completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
