import '../models/article.dart';
import '../models/media_item.dart';
import '../models/profile.dart';
import '../models/spot.dart';

const Profile mockProfile = Profile(
  username: 'demo_user',
  displayName: 'Demo User',
  bio: 'Skateboarding enthusiast 🛹',
  email: 'demo@nolla.net',
  website: 'https://nolla.net',
  followerCount: 42,
  followingCount: 17,
);

const List<MediaItem> mockFeedItems = [
  MediaItem(
    id: 1,
    url: 'https://picsum.photos/seed/skate1/800/600',
    mediaType: 'image',
    uploaderUsername: 'sk8er_pro',
    uploaderDisplayName: 'Skater Pro',
    spotName: 'Helsinki Skatepark',
    description: 'Perfect day at the park 🛹',
    likeCount: 24,
    commentCount: 5,
    createdAt: '2024-05-20T14:30:00Z',
  ),
  MediaItem(
    id: 2,
    url: 'https://picsum.photos/seed/skate2/800/600',
    mediaType: 'image',
    uploaderUsername: 'trickmaster',
    uploaderDisplayName: 'Trick Master',
    spotName: 'Kallio Bowl',
    description: 'New trick unlocked',
    likeCount: 57,
    commentCount: 12,
    createdAt: '2024-05-19T10:00:00Z',
  ),
  MediaItem(
    id: 3,
    url: 'https://picsum.photos/seed/skate3/800/600',
    mediaType: 'image',
    uploaderUsername: 'nollauser',
    uploaderDisplayName: 'Nolla User',
    description: 'Sunday session',
    likeCount: 8,
    commentCount: 1,
    createdAt: '2024-05-18T16:45:00Z',
  ),
  MediaItem(
    id: 4,
    url: 'https://picsum.photos/seed/skate4/800/600',
    mediaType: 'image',
    uploaderUsername: 'grindsalot',
    uploaderDisplayName: 'Grinds A Lot',
    spotName: 'Kamppi Rails',
    description: 'Nailed the 50-50',
    likeCount: 33,
    commentCount: 7,
    createdAt: '2024-05-17T09:15:00Z',
  ),
  MediaItem(
    id: 5,
    url: 'https://picsum.photos/seed/skate5/800/600',
    mediaType: 'image',
    uploaderUsername: 'flowrider',
    uploaderDisplayName: 'Flow Rider',
    spotName: 'Töölö Plaza',
    description: 'Smooth lines only',
    likeCount: 19,
    commentCount: 3,
    createdAt: '2024-05-16T12:00:00Z',
  ),
];

const List<Article> mockArticles = [
  Article(
    id: 1,
    title: 'Top 5 Skateparks in Helsinki',
    imageUrl: 'https://nolla.net/media/articles/helsinki-skateparks.jpg',
    author: 'Nolla Editorial',
    excerpt: 'Discover the best spots to skate in the Finnish capital, from indoor bowls to street plazas.',
    publishedAt: '2024-05-15T09:00:00Z',
    articleUrl: 'https://nolla.net/articles/top-5-skateparks-helsinki',
  ),
  Article(
    id: 2,
    title: 'Street Skating Culture in Finland',
    imageUrl: 'https://nolla.net/media/articles/street-skating-finland.jpg',
    author: 'Nolla Editorial',
    excerpt: 'How Finnish skaters have built a unique street scene over the past decade.',
    publishedAt: '2024-05-10T10:00:00Z',
    articleUrl: 'https://nolla.net/articles/street-skating-culture-finland',
  ),
  Article(
    id: 3,
    title: 'Beginner Tricks to Master This Summer',
    imageUrl: 'https://nolla.net/media/articles/beginner-tricks-summer.jpg',
    author: 'Nolla Editorial',
    excerpt: 'From ollies to kickflips — a guide to the fundamental tricks every skater should learn.',
    publishedAt: '2024-05-05T08:00:00Z',
    articleUrl: 'https://nolla.net/articles/beginner-tricks-summer',
  ),
  Article(
    id: 4,
    title: 'Interview: Pro Skater Mikko Leinonen',
    imageUrl: 'https://nolla.net/media/articles/mikko-leinonen-interview.jpg',
    author: 'Nolla Editorial',
    excerpt: 'We sat down with Finland\'s top pro skater to talk about his journey and what\'s next.',
    publishedAt: '2024-04-28T12:00:00Z',
    articleUrl: 'https://nolla.net/articles/mikko-leinonen-interview',
  ),
  Article(
    id: 5,
    title: 'New Spots Opening in Tampere',
    imageUrl: 'https://nolla.net/media/articles/tampere-new-spots.jpg',
    author: 'Nolla Editorial',
    excerpt: 'Tampere\'s skateboarding scene is growing fast — here are the newest places to skate.',
    publishedAt: '2024-04-20T14:00:00Z',
    articleUrl: 'https://nolla.net/articles/tampere-new-spots',
  ),
];

const List<Spot> mockSpots = [
  Spot(id: 1, name: 'Helsinki Skatepark', latitude: 60.1856, longitude: 24.9523, type: 'park', distance: 800),
  Spot(id: 2, name: 'Kallio Bowl', latitude: 60.1822, longitude: 24.9507, type: 'park', distance: 1200),
  Spot(id: 3, name: 'Kamppi Rails', latitude: 60.1692, longitude: 24.9327, type: 'terrain', distance: 400),
  Spot(id: 4, name: 'Töölö Plaza', latitude: 60.1752, longitude: 24.9240, type: 'terrain', distance: 650),
  Spot(id: 5, name: 'Eira Canal Banks', latitude: 60.1605, longitude: 24.9412, type: 'water', distance: 2100),
];
