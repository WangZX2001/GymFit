import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _friends = [];
  bool _isSearching = false;
  bool _isLoadingFriends = false;
  String? _currentUserId;
  final Set<String> _pendingFriendships = {};

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoadingFriends = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final friendIds = List<String>.from(userDoc.data()!['friends'] ?? []);
        
        if (friendIds.isNotEmpty) {
          final friendsQuery = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: friendIds)
              .get();

          setState(() {
            _friends = friendsQuery.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
          });
        } else {
          // If no friends, clear the friends list
          setState(() {
            _friends = [];
          });
        }
      } else {
        // If user document doesn't exist, clear friends list
        setState(() {
          _friends = [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading friends: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingFriends = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThan: '${query.toLowerCase()}\uf8ff')
          .limit(10)
          .get();

      final results = usersQuery.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .where((user) => user['id'] != _currentUserId)
          .toList();

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching users: $e')),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _addFriend(String friendId) async {
    if (_currentUserId == null) return;

    // Immediately add to pending friendships to trigger animation
    setState(() {
      _pendingFriendships.add(friendId);
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .update({
        'friends': FieldValue.arrayUnion([friendId])
      });

      // Also add current user to friend's friends list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .update({
        'friends': FieldValue.arrayUnion([_currentUserId])
      });

      // Provide haptic feedback for successful friend addition
      HapticFeedback.lightImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Friend added successfully!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Refresh friends list to sync with Firebase
      await _loadFriends();

      // Remove from pending since it's now in the real friends list
      setState(() {
        _pendingFriendships.remove(friendId);
      });

      // Allow time for animation to complete
      await Future.delayed(const Duration(milliseconds: 600));

      // Clear search to show updated friends list
      _searchController.clear();
      
      // Force a UI update to reflect the new friend status
      setState(() {
        _searchResults.clear();
        // This will trigger a rebuild and show the friends list with the new friend
      });
    } catch (e) {
      // Remove from pending on error
      setState(() {
        _pendingFriendships.remove(friendId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding friend: $e')),
        );
      }
    }
  }

  Future<void> _removeFriend(String friendId) async {
    if (_currentUserId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .update({
        'friends': FieldValue.arrayRemove([friendId])
      });

      // Also remove current user from friend's friends list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .update({
        'friends': FieldValue.arrayRemove([_currentUserId])
      });

      // Provide haptic feedback for successful friend removal
      HapticFeedback.selectionClick();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Friend removed successfully!'),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Small delay to ensure Firebase has processed
      await Future.delayed(const Duration(milliseconds: 200));

      // Refresh friends list
      await _loadFriends();

      // Trigger UI update
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing friend: $e')),
        );
      }
    }
  }

  bool _isFriend(String userId) {
    return _friends.any((friend) => friend['id'] == userId) || _pendingFriendships.contains(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Friends',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // Dismiss keyboard when tapping outside the search field
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            // Search Section
            Container(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search friends by username...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
              onChanged: (value) {
                _searchUsers(value);
              },
            ),
          ),

          // "My friends" text - only show when not searching and have friends
          if (_searchController.text.isEmpty && _friends.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'My friends',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),

          // Content Section
          Expanded(
            child: _searchController.text.isNotEmpty
                ? _buildSearchResults()
                : _buildFriendsList(),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && !_isSearching) {
      return const Center(
        child: Text(
          'No users found',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final isFriend = _isFriend(user['id']);

        return Card(
          color: Colors.white,
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                user['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              user['name'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('@${user['username'] ?? 'unknown'}'),
                         trailing: AnimatedSwitcher(
               duration: const Duration(milliseconds: 500),
               switchInCurve: Curves.elasticOut,
               switchOutCurve: Curves.easeInBack,
               transitionBuilder: (Widget child, Animation<double> animation) {
                 return ScaleTransition(
                   scale: animation,
                   child: child,
                 );
               },
               child: CircleAvatar(
                 key: ValueKey('${user['id']}_$isFriend'),
                 backgroundColor: isFriend 
                     ? Colors.green.shade100 
                     : Colors.blue.shade100,
                 child: IconButton(
                   onPressed: isFriend ? null : () => _addFriend(user['id']),
                   icon: Icon(
                     isFriend ? Icons.check : Icons.add,
                     color: isFriend 
                         ? Colors.green.shade700 
                         : Colors.blue.shade700,
                     size: 20,
                   ),
                 ),
               ),
             ),
          ),
        );
      },
    );
  }

  Widget _buildFriendsList() {
    if (_isLoadingFriends) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friends.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFriends,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No friends yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Search for friends using the search bar above',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriends,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
        final friend = _friends[index];

        return Card(
          color: Colors.white,
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Text(
                friend['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              friend['name'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
                          subtitle: Text('@${friend['username'] ?? 'unknown'}'),
                                                                              trailing: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.elasticOut,
                  switchOutCurve: Curves.easeInBack,
                                    transitionBuilder: (Widget child, Animation<double> animation) {
                   return ScaleTransition(
                     scale: animation,
                     child: child,
                   );
                  },
                  child: CircleAvatar(
                    key: ValueKey('friend_${friend['id']}'),
                 backgroundColor: Colors.green.shade100,
                 child: IconButton(
                   onPressed: () => _showRemoveFriendDialog(friend),
                   icon: Icon(
                     Icons.check,
                     color: Colors.green.shade700,
                     size: 20,
                   ),
                 ),
               ),
             ),
          ),
        );
      },
    ),
    );
  }

  void _showRemoveFriendDialog(Map<String, dynamic> friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove ${friend['name']} from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeFriend(friend['id']);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 