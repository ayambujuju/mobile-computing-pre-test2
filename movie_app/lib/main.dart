import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Catalog',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MovieListPage(),
    );
  }
}

// ===================== MODEL =====================
class Movie {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final double voteAverage;
  final String releaseDate;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.voteAverage,
    required this.releaseDate,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      releaseDate: json['release_date'] ?? '',
    );
  }
}

// ===================== LIST PAGE =====================
class MovieListPage extends StatefulWidget {
  const MovieListPage({super.key});

  @override
  State<MovieListPage> createState() => _MovieListPageState();
}

class _MovieListPageState extends State<MovieListPage> {
  List<Movie> movies = [];
  Set<int> favorites = {};
  bool isLoading = true;
  final String apiKey = '23400d7df8404e47e3725efd0f32a11e';

  @override
  void initState() {
    super.initState();
    fetchMovies();
  }

  Future<void> fetchMovies() async {
    final url = Uri.parse(
        'https://api.themoviedb.org/3/movie/popular?api_key=$apiKey&language=en-US&page=1');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        movies = (data['results'] as List)
            .map((e) => Movie.fromJson(e))
            .toList();
        isLoading = false;
      });
    }
  }

  void toggleFavorite(int id) {
    setState(() {
      if (favorites.contains(id)) {
        favorites.remove(id);
      } else {
        favorites.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Movie Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FavoritePage(
                    movies: movies.where((m) => favorites.contains(m.id)).toList(),
                    favorites: favorites,
                    onToggleFavorite: toggleFavorite,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                final isFav = favorites.contains(movie.id);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MovieDetailPage(
                            movie: movie,
                            isFavorite: isFav,
                            onToggleFavorite: () => toggleFavorite(movie.id),
                          ),
                        ),
                      );
                    },
                    leading: movie.posterPath.isNotEmpty
                        ? Image.network(
                            'https://image.tmdb.org/t/p/w92${movie.posterPath}',
                            width: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.movie),
                    title: Text(movie.title),
                    subtitle: Text(
                      movie.overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('⭐ ${movie.voteAverage.toStringAsFixed(1)}'),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => toggleFavorite(movie.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ===================== DETAIL PAGE =====================
class MovieDetailPage extends StatefulWidget {
  final Movie movie;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const MovieDetailPage({
    super.key,
    required this.movie,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  late bool isFav;

  @override
  void initState() {
    super.initState();
    isFav = widget.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(movie.title),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : Colors.grey,
            ),
            onPressed: () {
              setState(() => isFav = !isFav);
              widget.onToggleFavorite();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            movie.posterPath.isNotEmpty
                ? Image.network(
                    'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.movie, size: 100),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${movie.voteAverage.toStringAsFixed(1)} / 10',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 4),
                      Text(movie.releaseDate),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.overview,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== FAVORITE PAGE =====================
class FavoritePage extends StatelessWidget {
  final List<Movie> movies;
  final Set<int> favorites;
  final Function(int) onToggleFavorite;

  const FavoritePage({
    super.key,
    required this.movies,
    required this.favorites,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('My Favorites'),
      ),
      body: movies.isEmpty
          ? const Center(
              child: Text('Belum ada film favorit!',
                  style: TextStyle(fontSize: 18)),
            )
          : ListView.builder(
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: movie.posterPath.isNotEmpty
                        ? Image.network(
                            'https://image.tmdb.org/t/p/w92${movie.posterPath}',
                            width: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.movie),
                    title: Text(movie.title),
                    subtitle: Text('⭐ ${movie.voteAverage.toStringAsFixed(1)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () => onToggleFavorite(movie.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}