export const isOfferActive = (product, now = new Date()) => {
  if (!product?.isLimitedOffer || product.discountPrice == null) return false;
  if (product.offerStartsAt && now < new Date(product.offerStartsAt)) return false;
  if (product.offerEndsAt && now > new Date(product.offerEndsAt)) return false;
  return true;
};

export const serializeProduct = (product) => {
  const images = product.images || [];
  const liveOffer = isOfferActive(product);
  const price = Number(product.price);
  const discountPrice = product.discountPrice != null ? Number(product.discountPrice) : null;
  const displayPrice = liveOffer && discountPrice != null ? discountPrice : price;
  const primary = images.find((image) => image.isPrimary) || images[0];

  return {
    id: product.id,
    title: product.name,
    name: product.name,
    slug: product.slug,
    description: product.description,
    price,
    discountPrice,
    displayPrice,
    stockQuantity: product.stockQuantity,
    isActive: product.isActive,
    approvalStatus: String(product.approvalStatus || 'PENDING').toLowerCase(),
    isLimitedOffer: Boolean(product.isLimitedOffer),
    isOfferActive: liveOffer,
    offerStartsAt: product.offerStartsAt,
    offerEndsAt: product.offerEndsAt,
    rating: product.rating ?? 0,
    reviewCount: product._count?.reviews ?? product.reviews?.length ?? 0,
    category: product.category?.name || '',
    categoryId: product.categoryId,
    vendorId: product.vendorId,
    vendorName: product.vendor?.storeName || 'Quiver Lux Vendor',
    imageUrl: primary?.url || '',
    imageUrls: images.map((image) => image.url),
    images,
    createdAt: product.createdAt,
    updatedAt: product.updatedAt,
  };
};
