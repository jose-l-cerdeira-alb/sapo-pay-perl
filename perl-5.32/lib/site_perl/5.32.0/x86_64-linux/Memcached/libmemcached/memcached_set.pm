package Memcached::libmemcached::memcached_set;

=head1 NAME

memcached_set, memcached_add, memcached_replace - Store value on server

=head1 LIBRARY

C Client Library for memcached (libmemcached, -lmemcached)

=head1 SYNOPSIS

  #include <memcached.h>

  memcached_return_t
    memcached_set (memcached_st *ptr,
                   const char *key, size_t key_length, 
                   const char *value, size_t value_length, 
                   time_t expiration,
                   uint32_t flags);

  memcached_return_t
    memcached_add (memcached_st *ptr,
                   const char *key, size_t key_length,
                   const char *value, size_t value_length, 
                   time_t expiration,
                   uint32_t flags);

  memcached_return_t
    memcached_replace (memcached_st *ptr,
                       const char *key, size_t key_length,
                       const char *value, size_t value_length, 
                       time_t expiration,
                       uint32_t flags);

  memcached_return_t 
    memcached_prepend(memcached_st *ptr, 
                      const char *key, size_t key_length,
                      const char *value, size_t value_length, 
                      time_t expiration,
                      uint32_t flags)

  memcached_return_t 
    memcached_append(memcached_st *ptr, 
                     const char *key, size_t key_length,
                      const char *value, size_t value_length, 
                      time_t expiration,
                      uint32_t flags)
  memcached_return_t 
    memcached_cas(memcached_st *ptr, 
                  const char *key, size_t key_length,
                  const char *value, size_t value_length, 
                  time_t expiration,
                  uint32_t flags,
                  uint64_t cas);

  memcached_return_t 
    memcached_set_by_key(memcached_st *ptr, 
                         const char *master_key, size_t master_key_length, 
                         const char *key, size_t key_length, 
                         const char *value, size_t value_length, 
                         time_t expiration,
                         uint32_t flags);

  memcached_return_t 
    memcached_add_by_key(memcached_st *ptr, 
                         const char *master_key, size_t master_key_length,
                         const char *key, size_t key_length,
                         const char *value, size_t value_length, 
                         time_t expiration,
                         uint32_t flags);

  memcached_return_t 
    memcached_replace_by_key(memcached_st *ptr, 
                             const char *master_key, size_t master_key_length,
                             const char *key, size_t key_length,
                             const char *value, size_t value_length, 
                             time_t expiration,
                             uint32_t flags);

  memcached_return_t 
    memcached_prepend_by_key(memcached_st *ptr, 
                             const char *master_key, size_t master_key_length,
                             const char *key, size_t key_length,
                             const char *value, size_t value_length, 
                             time_t expiration,
                             uint32_t flags);

  memcached_return_t 
    memcached_append_by_key(memcached_st *ptr, 
                            const char *master_key, size_t master_key_length,
                            const char *key, size_t key_length,
                            const char *value, size_t value_length, 
                            time_t expiration,
                            uint32_t flags);

  memcached_return_t 
    memcached_cas_by_key(memcached_st *ptr, 
                         const char *master_key, size_t master_key_length,
                         const char *key, size_t key_length,
                         const char *value, size_t value_length, 
                         time_t expiration,
                         uint32_t flags,
                         uint64_t cas);

=head1 DESCRIPTION

memcached_set(), memcached_add(), and memcached_replace() are all used to
store information on the server. All methods take a key, and its length to
store the object. Keys are currently limited to 250 characters by the
memcached(1) server. You must also supply a value and a length. Optionally you
may support an expiration time for the object and a 16 byte value (it is
meant to be used as a bitmap).

memcached_set() will write an object to the server. If an object already
exists it will overwrite what is in the server. If the object does not exist
it will be written. If you are using the non-blocking mode this function
will always return true unless a network error occurs. 

memcached_replace() replaces an object on the server. If the object is not
found on the server an error occurs.

memcached_add() adds an object to the server. If the object is found on the
server an error occurs, otherwise the value is stored.

memcached_prepend() places a segment of data before the last piece of data 
stored. Currently expiration and key are not used in the server.

memcached_append() places a segment of data at the end of the last piece of 
data stored. Currently expiration and key are not used in the server.

memcached_cas() overwrites data in the server as long as the "cas" value is 
still the same in the server. You can get the cas value of a result by 
calling memcached_result_cas() on a memcached_result_st(3) structure. At the point 
that this note was written cas is still buggy in memached. Turning on support
for it in libmemcached(3) is optional. Please see memcached_set() for 
information on how to do this.

memcached_set_by_key(), memcached_add_by_key(), memcached_replace_by_key(), 
memcached_prepend_by_key(), memcached_append_by_key_by_key(), 
memcached_cas_by_key() methods all behave in a similar method as the non key 
methods. The difference is that they use their master_key parameter to map
objects to particular servers.

If you are looking for performance, memcached_set() with non-blocking IO is 
the fastest way to store data on the server.

All of the above functions are supported with the C<MEMCACHED_BEHAVIOR_USE_UDP>
behavior enabled. But when using these operations with this behavior on, there 
are limits to the size of the payload being sent to the server.  The reason for 
these limits is that the Memcahed Server does not allow multi-datagram requests
and the current server implementation sets a datagram size to 1400 bytes. Due 
to protocol overhead, the actual limit of the user supplied data is less than 
1400 bytes and depends on the protocol in use as well as the operation being 
executed. When running with the binary protocol, C< MEMCACHED_BEHAVIOR_BINARY_PROTOCOL>, 
the size of the key,value, flags and expiry combined may not exceed 1368 bytes. 
When running with the ASCII protocol, the exact limit fluctuates depending on 
which function is being executed and whether the function is a cas operation 
or not. For non-cas ASCII set operations, there are at least 1335 bytes available 
to split among the key, key_prefix, and value; for cas ASCII operations there are 
at least 1318 bytes available to split among the key, key_prefix and value. If the
total size of the command, including overhead, exceeds 1400 bytes, a C<MEMCACHED_WRITE_FAILURE>
will be returned.


=head1 RETURN

All methods return a value of type C<memcached_return_t>.
On success the value will be C<MEMCACHED_SUCCESS>.
Use memcached_strerror() to translate this value to a printable string.

For memcached_replace() and memcached_add(), C<MEMCACHED_NOTSTORED> is a
legitmate error in the case of a collision.

=head1 HOME

To find out more information please check:
L<https://launchpad.net/libmemcached>

=head1 AUTHOR

Brian Aker, E<lt>brian@tangent.orgE<gt>

=head1 SEE ALSO

memcached(1) libmemached(3) memcached_strerror(3)

=cut

1;