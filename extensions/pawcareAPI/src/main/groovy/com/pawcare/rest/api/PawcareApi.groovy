package com.pawcare.rest.api

import groovy.json.JsonSlurper
import groovy.sql.Sql
import org.bonitasoft.web.extension.rest.RestAPIContext
import org.bonitasoft.web.extension.rest.RestApiController
import org.bonitasoft.web.extension.rest.RestApiResponse
import org.bonitasoft.web.extension.rest.RestApiResponseBuilder

import javax.servlet.http.HttpServletRequest
import javax.servlet.http.HttpServletResponse

class PawcareApi implements RestApiController {

    @Override
    RestApiResponse doHandle(HttpServletRequest request,
                             RestApiResponseBuilder responseBuilder,
                             RestAPIContext context) {
        try {
            def result = Database.withSql { Sql sql ->
                new PawcareService(request, context, sql).dispatch()
            }

            return ApiResponse.json(
                    responseBuilder,
                    HttpServletResponse.SC_OK,
                    result as Serializable
            )
        } catch (ApiException exception) {
            return ApiResponse.error(
                    responseBuilder,
                    exception.status,
                    exception.message
            )
        } catch (Exception exception) {
            exception.printStackTrace()

            return ApiResponse.error(
                    responseBuilder,
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    exception.message ?: 'Unexpected server error'
            )
        }
    }
}

class PawcareService {

    private final HttpServletRequest request
    private final RestAPIContext context
    private final Sql sql

    private static final Map<String, Map> RESOURCES = [
            pets: [
                    table : 'pets',
                    fields: [
                            'owner_profile_id', 'name', 'species', 'breed',
                            'gender', 'birth_date', 'weight_kg', 'color', 'medical_notes',
                            'is_active'
                    ]
            ],
            providers: [
                    table : 'providers',
                    fields: [
                            'owner_profile_id', 'provider_type', 'name',
                            'phone', 'email', 'address', 'service_area',
                            'description', 'status', 'rejection_reason', 'is_active'
                    ]
            ],
            categories: [
                    table : 'service_categories',
                    fields: ['name', 'description', 'is_active']
            ],
            services: [
                    table : 'services',
                    fields: [
                            'provider_id', 'category_id', 'name',
                            'description', 'price', 'duration_minutes', 'pet_type_supported',
                            'is_active'
                    ]
            ],
            staff: [
                    table : 'staff',
                    fields: [
                            'provider_id', 'full_name', 'phone', 'email',
                            'skills', 'is_active'
                    ]
            ],
            schedules: [
                    table : 'staff_schedules',
                    fields: [
                            'staff_id', 'start_at', 'end_at', 'status', 'note'
                    ]
            ]
    ]

    PawcareService(HttpServletRequest request,
                   RestAPIContext context,
                   Sql sql) {
        this.request = request
        this.context = context
        this.sql = sql
    }

    Map dispatch() {
        String action = request.requestURI.tokenize('/').last().toLowerCase()
        String method = request.method.toUpperCase()

        if (action == 'health' && method == 'GET') {
            return [
                    success : true,
                    message : 'PawCare API connected to MySQL successfully',
                    database: sql.firstRow('SELECT DATABASE() AS database_name').database_name
            ]
        }

        if (action == 'users-me' && method == 'GET') {
            return currentUserResponse()
        }

        if (action == 'users') {
            return handleUsers(method)
        }

        if (action in ['bookings', 'payments', 'reviews', 'notifications']) {
            return handleMt5(action, method)
        }

        if (action == 'complaints') {
            return handleComplaints(method)
        }

        if (!RESOURCES.containsKey(action)) {
            throw new ApiException(404, "Unknown endpoint: ${action}")
        }

        return handleResource(action, method)
    }

    private Map currentUserResponse() {
        Long bonitaUserId = currentBonitaUserId()
        Map profile = currentProfile(false)

        return [
                bonita_user_id: bonitaUserId,
                profile       : profile,
                mapped        : profile != null
        ]
    }

    private Object handleUsers(String method) {
        switch (method) {
            case 'GET':
                requireAdmin()
                return listRows('user_profiles', query('role_code'), query('is_active'))

            case 'POST':
                requireAdmin()
                return insert('user_profiles', [
                        'bonita_user_id', 'full_name', 'phone', 'email',
                        'address', 'role_code', 'is_active'
                ], requestBody())

            case 'PUT':
                requireAdmin()
                return update('user_profiles', [
                        'full_name', 'phone', 'email', 'address',
                        'role_code', 'is_active'
                ], requestBody())

            default:
                throw new ApiException(405, "Method ${method} is not allowed for users")
        }
    }

    private Object handleResource(String resource, String method) {
        Map definition = RESOURCES[resource]

        switch (method) {
            case 'GET':
                return listResource(resource, definition)

            case 'POST':
                return createResource(resource, definition)

            case 'PUT':
                return updateResource(resource, definition)

            case 'DELETE':
                return deleteResource(resource, definition)

            default:
                throw new ApiException(405, "Method ${method} is not allowed for ${resource}")
        }
    }

    private Object listResource(String resource, Map definition) {
        Map profile = currentProfile(false)

        if (resource in ['providers', 'categories', 'services']) {
            return listRows(definition.table, null, null)
        }

        requireProfile(profile)

        switch (resource) {
            case 'pets':
                if (isAdmin(profile)) {
                    return listRows(definition.table, null, null)
                }

                return listRows(
                        definition.table,
                        'owner_profile_id = ?',
                        [profile.id]
                )

            case 'staff':
                if (isAdmin(profile)) {
                    return listRows(definition.table, null, null)
                }

                return listRows(
                        'staff s JOIN providers p ON p.id = s.provider_id',
                        'p.owner_profile_id = ?',
                        [profile.id],
                        's.*',
                        's.id'
                )

            case 'schedules':
                if (isAdmin(profile)) {
                    return listRows(definition.table, null, null)
                }

                return listRows(
                        'staff_schedules ss ' +
                                'JOIN staff s ON s.id = ss.staff_id ' +
                                'JOIN providers p ON p.id = s.provider_id',
                        'p.owner_profile_id = ?',
                        [profile.id],
                        'ss.*',
                        'ss.id'
                )

            default:
                return listRows(definition.table, null, null)
        }
    }

    private Map createResource(String resource, Map definition) {
        Map profile = requireProfile(currentProfile(false))
        Map body = requestBody()

        switch (resource) {
            case 'pets':
                requireRole(profile, ['CUSTOMER', 'ADMIN'])
                if (!isAdmin(profile)) {
                    body.owner_profile_id = profile.id
                }
                break

            case 'providers':
                requireRole(profile, ['PROVIDER', 'ADMIN'])
                if (!isAdmin(profile)) {
                    body.owner_profile_id = profile.id
                    body.status = 'PENDING'
                }
                break

            case 'categories':
                requireAdmin()
                break

            case 'services':
            case 'staff':
                requireRole(profile, ['PROVIDER', 'ADMIN'])
                if (!isAdmin(profile)) {
                    body.provider_id = ownedProviderId(profile)
                }
                break

            case 'schedules':
                requireRole(profile, ['PROVIDER', 'ADMIN'])
                if (!isAdmin(profile)) {
                    assertStaffBelongsToProvider(
                            asLong(body.staff_id, 'staff_id'),
                            ownedProviderId(profile)
                    )
                }
                break
        }

        return insert(definition.table, definition.fields, body)
    }

    private Map updateResource(String resource, Map definition) {
        Map profile = requireProfile(currentProfile(false))
        Map body = requestBody()
        Long id = asLong(body.id, 'id')

        switch (resource) {
            case 'pets':
                requireRole(profile, ['CUSTOMER', 'ADMIN'])
                if (!isAdmin(profile)) {
                    assertPetOwner(id, profile.id as Long)
                }
                break

            case 'providers':
                requireRole(profile, ['PROVIDER', 'ADMIN'])
                if (!isAdmin(profile)) {
                    assertProviderOwner(id, profile.id as Long)
                    body.remove('status')
                    body.remove('owner_profile_id')
                }
                break

            case 'categories':
                requireAdmin()
                break

            case 'services':
                requireRole(profile, ['PROVIDER', 'ADMIN'])
                if (!isAdmin(profile)) {
                    assertServiceOwner(id, ownedProviderId(profile))
                    body.provider_id = ownedProviderId(profile)
                }
                break

            case 'staff':
                requireRole(profile, ['PROVIDER', 'ADMIN'])
                if (!isAdmin(profile)) {
                    assertStaffOwner(id, ownedProviderId(profile))
                    body.provider_id = ownedProviderId(profile)
                }
                break

            case 'schedules':
                requireRole(profile, ['PROVIDER', 'ADMIN'])
                if (!isAdmin(profile)) {
                    assertScheduleOwner(id, ownedProviderId(profile))
                    if (body.staff_id) {
                        assertStaffBelongsToProvider(
                                asLong(body.staff_id, 'staff_id'),
                                ownedProviderId(profile)
                        )
                    }
                }
                break
        }

        return update(definition.table, definition.fields, body)
    }

    private Map deleteResource(String resource, Map definition) {
        Map profile = requireProfile(currentProfile(false))
        Long id = asLong(query('id'), 'id')

        switch (resource) {
            case 'pets':
                requireRole(profile, ['CUSTOMER', 'ADMIN'])
                if (!isAdmin(profile)) {
                    assertPetOwner(id, profile.id as Long)
                }
                break

            case 'providers':
                requireRole(profile, ['PROVIDER', 'ADMIN'])
                if (!isAdmin(profile)) {
                    assertProviderOwner(id, profile.id as Long)
                }

                sql.executeUpdate(
                        'UPDATE providers SET status = ?, is_active = 0 WHERE id = ?',
                        ['SUSPENDED', id]
                )

                return [
                        success: true,
                        message: 'Provider has been suspended',
                        id     : id
                ]

            case 'categories':
                requireAdmin()
                break

            case 'services':
                requireRole(profile, ['PROVIDER', 'ADMIN'])
                if (!isAdmin(profile)) {
                    assertServiceOwner(id, ownedProviderId(profile))
                }
                break

            case 'staff':
                requireRole(profile, ['PROVIDER', 'ADMIN'])
                if (!isAdmin(profile)) {
                    assertStaffOwner(id, ownedProviderId(profile))
                }
                break

            case 'schedules':
                requireRole(profile, ['PROVIDER', 'ADMIN'])
                if (!isAdmin(profile)) {
                    assertScheduleOwner(id, ownedProviderId(profile))
                }
                break
        }

        int affected = sql.executeUpdate(
                "DELETE FROM ${definition.table} WHERE id = ?",
                [id]
        )

        if (affected == 0) {
            throw new ApiException(404, 'Record not found')
        }

        return [success: true, id: id]
    }

    private Object handleMt5(String resource, String method) {
        switch (resource) {
            case 'bookings':
                return handleBookings(method)
            case 'payments':
                return handlePayments(method)
            case 'reviews':
                return handleReviews(method)
            case 'notifications':
                return handleNotifications(method)
            default:
                throw new ApiException(404, "Unknown endpoint: ${resource}")
        }
    }

    private Object handleBookings(String method) {
        Map profile = requireProfile(currentProfile(false))
        switch (method) {
            case 'GET':
                return listBookings(profile)
            case 'POST':
                return createBooking(profile, requestBody())
            case 'PUT':
                return updateBooking(profile, requestBody())
            case 'DELETE':
                return cancelBooking(profile, asLong(query('id'), 'id'))
            default:
                throw new ApiException(405, "Method ${method} is not allowed for bookings")
        }
    }

    private Map listBookings(Map profile) {
        String where = ''
        List values = []
        if (!isAdmin(profile)) {
            if (profile.role_code == 'CUSTOMER') {
                where = 'b.customer_profile_id = ?'
                values << profile.id
            } else if (profile.role_code == 'PROVIDER') {
                where = 'p.owner_profile_id = ?'
                values << profile.id
            } else {
                throw new ApiException(403, 'You do not have permission to view bookings')
            }
        }
        String status = query('status')
        if (status) {
            where += where ? ' AND b.status = ?' : 'b.status = ?'
            values << status
        }
        return listRows(
                'bookings b JOIN providers p ON p.id = b.provider_id', where, values,
                'b.*, p.name AS provider_name', 'b.id'
        )
    }

    private Map createBooking(Map profile, Map body) {
        requireRole(profile, ['CUSTOMER'])
        Long petId = asLong(body.pet_id, 'pet_id')
        Long providerId = asLong(body.provider_id, 'provider_id')
        Long serviceId = asLong(body.service_id, 'service_id')
        String bookingStart = requiredText(body.booking_start, 'booking_start')
        assertPetOwner(petId, profile.id as Long)
        Map service = sql.firstRow(
                'SELECT id, provider_id, price, duration_minutes FROM services WHERE id = ? AND provider_id = ? AND is_active = 1',
                [serviceId, providerId]
        )
        if (service == null) {
            throw new ApiException(400, 'Service must be active and belong to the selected provider')
        }
        Long staffId = body.staff_id ? asLong(body.staff_id, 'staff_id') : null
        if (staffId != null) {
            assertStaffBelongsToProvider(staffId, providerId)
            assertStaffIsAvailable(staffId, bookingStart, service.duration_minutes as Integer)
        }
        String bookingEnd = body.booking_end?.toString()?.trim()
        if (!bookingEnd) {
            bookingEnd = sql.firstRow('SELECT DATE_ADD(?, INTERVAL ? MINUTE) AS value',
                    [bookingStart, service.duration_minutes]).value?.toString()
        }
        List keys = sql.executeInsert('''
            INSERT INTO bookings (customer_profile_id, pet_id, provider_id, service_id, staff_id,
                                  booking_start, booking_end, estimated_price, customer_note)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', [profile.id, petId, providerId, serviceId, staffId, bookingStart, bookingEnd,
              service.price, body.customer_note])
        Long bookingId = keys[0][0] as Long
        addBookingHistory(bookingId, null, 'PENDING', profile.id as Long, 'Customer created booking')
        Map provider = sql.firstRow('SELECT owner_profile_id FROM providers WHERE id = ?', [providerId])
        notifyProfile(provider.owner_profile_id as Long, 'New booking request',
                "A customer created booking #${bookingId}", 'BOOKING', 'BOOKING', bookingId)
        return [success: true, id: bookingId, data: bookingById(bookingId)]
    }

    private Map updateBooking(Map profile, Map body) {
        Long bookingId = asLong(body.id, 'id')
        Map booking = bookingById(bookingId)
        String previous = booking.status as String
        String next = requiredText(body.status, 'status').toUpperCase()
        boolean ownerCustomer = booking.customer_profile_id as Long == profile.id as Long
        boolean ownerProvider = providerOwnedByProfile(booking.provider_id as Long, profile.id as Long)

        if (isAdmin(profile)) {
            // Admin may apply any valid business transition.
        } else if (ownerProvider && profile.role_code == 'PROVIDER') {
            if (!(next in ['CONFIRMED', 'REJECTED', 'CHECKED_IN', 'IN_SERVICE', 'COMPLETED'])) {
                throw new ApiException(403, 'Provider cannot set this booking status')
            }
        } else if (ownerCustomer && profile.role_code == 'CUSTOMER' && next == 'CANCELLED') {
            // Customer cancellation is allowed before service completion.
        } else {
            throw new ApiException(403, 'You do not have permission to update this booking')
        }
        assertBookingTransition(previous, next)
        sql.executeUpdate('''
            UPDATE bookings
            SET status = ?, provider_note = COALESCE(?, provider_note),
                cancel_reason = CASE WHEN ? = 'CANCELLED' THEN ? ELSE cancel_reason END,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        ''', [next, body.provider_note, next, body.cancel_reason, bookingId])
        addBookingHistory(bookingId, previous, next, profile.id as Long, body.note?.toString())
        notifyProfile(booking.customer_profile_id as Long, 'Booking status updated',
                "Booking #${bookingId} is now ${next}", 'BOOKING', 'BOOKING', bookingId)
        return [success: true, id: bookingId, data: bookingById(bookingId)]
    }

    private Map cancelBooking(Map profile, Long bookingId) {
        Map booking = bookingById(bookingId)
        boolean allowed = isAdmin(profile) ||
                ((booking.customer_profile_id as Long) == (profile.id as Long) && profile.role_code == 'CUSTOMER')
        if (!allowed) {
            throw new ApiException(403, 'You do not have permission to cancel this booking')
        }
        String previous = booking.status as String
        assertBookingTransition(previous, 'CANCELLED')
        String reason = query('reason') ?: 'Cancelled by user'
        sql.executeUpdate('UPDATE bookings SET status = ?, cancel_reason = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
                ['CANCELLED', reason, bookingId])
        addBookingHistory(bookingId, previous, 'CANCELLED', profile.id as Long, reason)
        return [success: true, id: bookingId, data: bookingById(bookingId)]
    }

    private Object handlePayments(String method) {
        Map profile = requireProfile(currentProfile(false))
        switch (method) {
            case 'GET': return listPayments(profile)
            case 'POST': return createPayment(profile, requestBody())
            case 'PUT': return simulatePayment(profile, requestBody())
            default: throw new ApiException(405, "Method ${method} is not allowed for payments")
        }
    }

    private Map listPayments(Map profile) {
        String where = ''
        List values = []
        if (!isAdmin(profile)) {
            if (profile.role_code == 'CUSTOMER') {
                where = 'b.customer_profile_id = ?'
                values << profile.id
            } else if (profile.role_code == 'PROVIDER') {
                where = 'pr.owner_profile_id = ?'
                values << profile.id
            } else {
                throw new ApiException(403, 'You do not have permission to view payments')
            }
        }
        return listRows('payments pay JOIN bookings b ON b.id = pay.booking_id JOIN providers pr ON pr.id = b.provider_id',
                where, values, 'pay.*, b.status AS booking_status', 'pay.id')
    }

    private Map createPayment(Map profile, Map body) {
        requireRole(profile, ['CUSTOMER'])
        Long bookingId = asLong(body.booking_id, 'booking_id')
        Map booking = bookingById(bookingId)
        if ((booking.customer_profile_id as Long) != (profile.id as Long)) {
            throw new ApiException(403, 'You can only pay for your own booking')
        }
        if (!(booking.status in ['PENDING', 'CONFIRMED'])) {
            throw new ApiException(400, 'Payment can only be created for a pending or confirmed booking')
        }
        if (sql.firstRow('SELECT id FROM payments WHERE booking_id = ?', [bookingId])) {
            throw new ApiException(409, 'A payment already exists for this booking')
        }
        String method = requiredText(body.payment_method, 'payment_method').toUpperCase()
        if (!(method in ['MOCK_CASH', 'MOCK_CARD', 'MOCK_EWALLET'])) {
            throw new ApiException(400, 'payment_method must be MOCK_CASH, MOCK_CARD, or MOCK_EWALLET')
        }
        List keys = sql.executeInsert('INSERT INTO payments (booking_id, amount, payment_method) VALUES (?, ?, ?)',
                [bookingId, booking.estimated_price, method])
        Long id = keys[0][0] as Long
        return [success: true, id: id, data: sql.firstRow('SELECT * FROM payments WHERE id = ?', [id])]
    }

    private Map simulatePayment(Map profile, Map body) {
        Long paymentId = asLong(body.id, 'id')
        Map payment = sql.firstRow('''
            SELECT pay.*, b.customer_profile_id, b.provider_id
            FROM payments pay JOIN bookings b ON b.id = pay.booking_id WHERE pay.id = ?
        ''', [paymentId])
        if (payment == null) throw new ApiException(404, 'Payment not found')
        boolean owner = profile.role_code == 'CUSTOMER' &&
                (payment.customer_profile_id as Long) == (profile.id as Long)
        if (!(owner || isAdmin(profile))) throw new ApiException(403, 'You do not have permission to simulate this payment')
        String status = requiredText(body.status, 'status').toUpperCase()
        if (!(status in ['PAID', 'FAILED', 'REFUNDED'])) throw new ApiException(400, 'status must be PAID, FAILED, or REFUNDED')
        if (status == 'REFUNDED' && !isAdmin(profile)) throw new ApiException(403, 'Only an admin can refund a payment')
        String reference = body.transaction_reference?.toString()?.trim() ?: "MOCK-${paymentId}-${System.currentTimeMillis()}"
        sql.executeUpdate('''
            UPDATE payments SET status = ?, transaction_reference = ?,
            paid_at = CASE WHEN ? = 'PAID' THEN CURRENT_TIMESTAMP ELSE paid_at END,
            updated_at = CURRENT_TIMESTAMP WHERE id = ?
        ''', [status, reference, status, paymentId])
        notifyProfile(payment.customer_profile_id as Long, 'Payment updated',
                "Payment #${paymentId} is ${status}", 'PAYMENT', 'PAYMENT', paymentId)
        return [success: true, id: paymentId, data: sql.firstRow('SELECT * FROM payments WHERE id = ?', [paymentId])]
    }

    private Object handleReviews(String method) {
        Map profile = currentProfile(false)
        switch (method) {
            case 'GET': return listRows('reviews', 'is_visible = 1', [])
            case 'POST': return createReview(requireProfile(profile), requestBody())
            case 'PUT': return updateReview(requireProfile(profile), requestBody())
            case 'DELETE': return deleteReview(requireProfile(profile), asLong(query('id'), 'id'))
            default: throw new ApiException(405, "Method ${method} is not allowed for reviews")
        }
    }

    private Map createReview(Map profile, Map body) {
        requireRole(profile, ['CUSTOMER'])
        Long bookingId = asLong(body.booking_id, 'booking_id')
        Map booking = bookingById(bookingId)
        if ((booking.customer_profile_id as Long) != (profile.id as Long) || booking.status != 'COMPLETED') {
            throw new ApiException(403, 'You can review only your own completed booking')
        }
        if (sql.firstRow('SELECT id FROM reviews WHERE booking_id = ?', [bookingId])) {
            throw new ApiException(409, 'This booking already has a review')
        }
        int rating = integerBody(body.rating, 'rating')
        if (rating < 1 || rating > 5) throw new ApiException(400, 'rating must be between 1 and 5')
        List keys = sql.executeInsert('''
            INSERT INTO reviews (booking_id, customer_profile_id, provider_id, rating, comment)
            VALUES (?, ?, ?, ?, ?)
        ''', [bookingId, profile.id, booking.provider_id, rating, body.comment])
        Long id = keys[0][0] as Long
        Map provider = sql.firstRow('SELECT owner_profile_id FROM providers WHERE id = ?', [booking.provider_id])
        notifyProfile(provider.owner_profile_id as Long, 'New review received',
                "Booking #${bookingId} received a ${rating}-star review", 'REVIEW', 'REVIEW', id)
        return [success: true, id: id, data: sql.firstRow('SELECT * FROM reviews WHERE id = ?', [id])]
    }

    private Map updateReview(Map profile, Map body) {
        Long id = asLong(body.id, 'id')
        Map review = sql.firstRow('SELECT * FROM reviews WHERE id = ?', [id])
        if (review == null) throw new ApiException(404, 'Review not found')
        boolean owner = profile.role_code == 'CUSTOMER' && (review.customer_profile_id as Long) == (profile.id as Long)
        if (!(owner || isAdmin(profile))) throw new ApiException(403, 'You do not have permission to update this review')
        List values = []
        String set = ''
        if (body.containsKey('rating')) {
            int rating = integerBody(body.rating, 'rating')
            if (rating < 1 || rating > 5) throw new ApiException(400, 'rating must be between 1 and 5')
            set += 'rating = ?'; values << rating
        }
        if (body.containsKey('comment')) { set += set ? ', comment = ?' : 'comment = ?'; values << body.comment }
        if (isAdmin(profile) && body.containsKey('is_visible')) { set += set ? ', is_visible = ?' : 'is_visible = ?'; values << body.is_visible }
        if (!set) throw new ApiException(400, 'No valid fields to update')
        values << id
        sql.executeUpdate("UPDATE reviews SET ${set}, updated_at = CURRENT_TIMESTAMP WHERE id = ?", values)
        return [success: true, id: id, data: sql.firstRow('SELECT * FROM reviews WHERE id = ?', [id])]
    }

    private Map deleteReview(Map profile, Long id) {
        Map review = sql.firstRow('SELECT * FROM reviews WHERE id = ?', [id])
        if (review == null) throw new ApiException(404, 'Review not found')
        boolean owner = profile.role_code == 'CUSTOMER' && (review.customer_profile_id as Long) == (profile.id as Long)
        if (!(owner || isAdmin(profile))) throw new ApiException(403, 'You do not have permission to delete this review')
        sql.executeUpdate('DELETE FROM reviews WHERE id = ?', [id])
        return [success: true, id: id]
    }

    private Object handleComplaints(String method) {
        Map profile = requireProfile(currentProfile(false))
        switch (method) {
            case 'GET':
                if (!isAdmin(profile)) throw new ApiException(403, 'Admin permission is required')
                return listRows(
                        'complaints c JOIN user_profiles u ON u.id = c.customer_profile_id JOIN providers p ON p.id = c.provider_id',
                        null, [],
                        'c.*, u.full_name AS customer_name, u.email AS customer_email, p.name AS provider_name', 'c.id'
                )
            case 'POST':
                return createComplaint(profile, requestBody())
            case 'PUT':
                return updateComplaint(profile, requestBody())
            default:
                throw new ApiException(405, "Method ${method} is not allowed for complaints")
        }
    }

    private Map createComplaint(Map profile, Map body) {
        requireRole(profile, ['CUSTOMER'])
        Long bookingId = asLong(body.booking_id, 'booking_id')
        Map booking = bookingById(bookingId)
        if ((booking.customer_profile_id as Long) != (profile.id as Long)) {
            throw new ApiException(403, 'You can only create a complaint for your own booking')
        }
        String content = requiredText(body.content, 'content')
        List keys = sql.executeInsert('''
            INSERT INTO complaints (booking_id, customer_profile_id, provider_id, content)
            VALUES (?, ?, ?, ?)
        ''', [bookingId, profile.id, booking.provider_id, content])
        Long id = keys[0][0] as Long
        Map provider = sql.firstRow('SELECT owner_profile_id FROM providers WHERE id = ?', [booking.provider_id])
        notifyProfile(provider.owner_profile_id as Long, 'New complaint',
                "Booking #${bookingId} has a new complaint", 'COMPLAINT', 'COMPLAINT', id)
        return [success: true, id: id, data: sql.firstRow('SELECT * FROM complaints WHERE id = ?', [id])]
    }

    private Map updateComplaint(Map profile, Map body) {
        if (!isAdmin(profile)) throw new ApiException(403, 'Admin permission is required')
        Long id = asLong(body.id, 'id')
        String status = requiredText(body.status, 'status').toUpperCase()
        if (!(status in ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'REJECTED'])) {
            throw new ApiException(400, 'status must be OPEN, IN_PROGRESS, RESOLVED, or REJECTED')
        }
        int affected = sql.executeUpdate('''
            UPDATE complaints
            SET status = ?, admin_response = COALESCE(?, admin_response),
                resolved_at = CASE WHEN ? IN ('RESOLVED', 'REJECTED') THEN CURRENT_TIMESTAMP ELSE resolved_at END
            WHERE id = ?
        ''', [status, body.admin_response, status, id])
        if (affected == 0) throw new ApiException(404, 'Complaint not found')
        Map complaint = sql.firstRow('SELECT * FROM complaints WHERE id = ?', [id])
        notifyProfile(complaint.customer_profile_id as Long, 'Complaint updated',
                "Complaint #${id} is now ${status}", 'COMPLAINT', 'COMPLAINT', id)
        return [success: true, id: id, data: complaint]
    }

    private Object handleNotifications(String method) {
        Map profile = requireProfile(currentProfile(false))
        switch (method) {
            case 'GET':
                return isAdmin(profile) && query('all') == 'true'
                        ? listRows('notifications', null, [])
                        : listRows('notifications', 'recipient_profile_id = ?', [profile.id])
            case 'PUT':
                Long id = asLong(requestBody().id, 'id')
                int affected = sql.executeUpdate('''
                    UPDATE notifications SET is_read = 1, read_at = CURRENT_TIMESTAMP
                    WHERE id = ? AND recipient_profile_id = ?
                ''', [id, profile.id])
                if (affected == 0) throw new ApiException(404, 'Notification not found')
                return [success: true, id: id]
            default:
                throw new ApiException(405, "Method ${method} is not allowed for notifications")
        }
    }

    private Map bookingById(Long id) {
        Map booking = sql.firstRow('SELECT * FROM bookings WHERE id = ?', [id])
        if (booking == null) throw new ApiException(404, 'Booking not found')
        return booking
    }

    private boolean providerOwnedByProfile(Long providerId, Long profileId) {
        return sql.firstRow('SELECT id FROM providers WHERE id = ? AND owner_profile_id = ?', [providerId, profileId]) != null
    }

    private void assertStaffIsAvailable(Long staffId, String startAt, Integer durationMinutes) {
        Map conflict = sql.firstRow('''
            SELECT id FROM bookings
            WHERE staff_id = ? AND status IN ('PENDING', 'CONFIRMED', 'CHECKED_IN', 'IN_SERVICE')
              AND booking_start < DATE_ADD(?, INTERVAL ? MINUTE)
              AND booking_end > ?
            LIMIT 1
        ''', [staffId, startAt, durationMinutes, startAt])
        if (conflict != null) throw new ApiException(409, 'Selected staff already has an overlapping booking')
    }

    private void assertBookingTransition(String previous, String next) {
        Map<String, List<String>> allowed = [
                PENDING    : ['CONFIRMED', 'REJECTED', 'CANCELLED'],
                CONFIRMED  : ['CHECKED_IN', 'CANCELLED'],
                CHECKED_IN : ['IN_SERVICE', 'CANCELLED'],
                IN_SERVICE : ['COMPLETED'],
                COMPLETED  : [], REJECTED: [], CANCELLED: []
        ]
        if (!(next in (allowed[previous] ?: []))) {
            throw new ApiException(400, "Cannot change booking from ${previous} to ${next}")
        }
    }

    private void addBookingHistory(Long bookingId, String previous, String next, Long actorId, String note) {
        sql.executeInsert('''
            INSERT INTO booking_status_history (booking_id, previous_status, new_status, changed_by_profile_id, note)
            VALUES (?, ?, ?, ?, ?)
        ''', [bookingId, previous, next, actorId, note])
    }

    private void notifyProfile(Long recipientProfileId, String title, String content,
                               String type, String referenceType, Long referenceId) {
        if (recipientProfileId == null) return
        sql.executeInsert('''
            INSERT INTO notifications (recipient_profile_id, title, content, notification_type, reference_type, reference_id)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', [recipientProfileId, title, content, type, referenceType, referenceId])
    }

    private String requiredText(Object value, String fieldName) {
        if (value == null || value.toString().trim().isEmpty()) throw new ApiException(400, "${fieldName} is required")
        return value.toString().trim()
    }

    private int integerBody(Object value, String fieldName) {
        try { return Integer.parseInt(value.toString()) }
        catch (Exception ignored) { throw new ApiException(400, "${fieldName} must be an integer") }
    }

    private Map insert(String table, List<String> allowedFields, Map body) {
        List<String> fields = allowedFields.findAll { body.containsKey(it) }

        if (fields.isEmpty()) {
            throw new ApiException(400, 'Request body has no valid fields')
        }

        String columns = fields.join(', ')
        String placeholders = fields.collect { '?' }.join(', ')
        List values = fields.collect { body[it] }

        List keys = sql.executeInsert(
                "INSERT INTO ${table} (${columns}) VALUES (${placeholders})",
                values
        )

        Long id = keys[0][0] as Long

        return [
                success: true,
                id     : id,
                data   : sql.firstRow("SELECT * FROM ${table} WHERE id = ?", [id])
        ]
    }

    private Map update(String table, List<String> allowedFields, Map body) {
        Long id = asLong(body.id, 'id')
        List<String> fields = allowedFields.findAll { body.containsKey(it) }

        if (fields.isEmpty()) {
            throw new ApiException(400, 'Request body has no valid fields to update')
        }

        String assignments = fields.collect { "${it} = ?" }.join(', ')
        List values = fields.collect { body[it] }
        values << id

        int affected = sql.executeUpdate(
                "UPDATE ${table} SET ${assignments}, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
                values
        )

        if (affected == 0) {
            throw new ApiException(404, 'Record not found')
        }

        return [
                success: true,
                id     : id,
                data   : sql.firstRow("SELECT * FROM ${table} WHERE id = ?", [id])
        ]
    }

    private Map listRows(String table,
                         String whereClause,
                         List values = [],
                         String selectedColumns = '*',
                         String orderColumn = 'id') {
        int page = integerQuery('p', 0)
        int count = Math.min(integerQuery('c', 20), 100)
        int offset = page * count

        String where = whereClause ? " WHERE ${whereClause}" : ''
        String query = "SELECT ${selectedColumns} FROM ${table}${where} ORDER BY ${orderColumn} DESC LIMIT ? OFFSET ?"

        List parameters = []
        parameters.addAll(values ?: [])
        parameters << count
        parameters << offset

        List rows = sql.rows(query, parameters)

        return [
                page : page,
                count: count,
                data : rows
        ]
    }

    private Map currentProfile(boolean failWhenMissing = true) {
        Map profile = sql.firstRow(
                'SELECT * FROM user_profiles WHERE bonita_user_id = ? AND is_active = 1',
                [currentBonitaUserId()]
        )

        if (profile == null && failWhenMissing) {
            throw new ApiException(
                    403,
                    'Your Bonita account has not been linked to a PawCare profile yet'
            )
        }

        return profile
    }

    private Long currentBonitaUserId() {
        return context.apiSession.userId as Long
    }

    private Map requireProfile(Map profile) {
        if (profile == null) {
            throw new ApiException(
                    403,
                    'Your Bonita account has not been linked to a PawCare profile yet'
            )
        }

        return profile
    }

    private void requireAdmin() {
        Map profile = requireProfile(currentProfile(false))
        requireRole(profile, ['ADMIN'])
    }

    private void requireRole(Map profile, List<String> roles) {
        if (!(profile.role_code in roles)) {
            throw new ApiException(403, 'You do not have permission for this action')
        }
    }

    private boolean isAdmin(Map profile) {
        return profile?.role_code == 'ADMIN'
    }

    private Long ownedProviderId(Map profile) {
        Map provider = sql.firstRow(
                'SELECT id FROM providers WHERE owner_profile_id = ? AND is_active = 1',
                [profile.id]
        )

        if (provider == null) {
            throw new ApiException(403, 'Your profile does not own an active provider')
        }

        return provider.id as Long
    }

    private void assertPetOwner(Long petId, Long profileId) {
        assertOwned(
                'SELECT id FROM pets WHERE id = ? AND owner_profile_id = ?',
                [petId, profileId]
        )
    }

    private void assertProviderOwner(Long providerId, Long profileId) {
        assertOwned(
                'SELECT id FROM providers WHERE id = ? AND owner_profile_id = ?',
                [providerId, profileId]
        )
    }

    private void assertServiceOwner(Long serviceId, Long providerId) {
        assertOwned(
                'SELECT id FROM services WHERE id = ? AND provider_id = ?',
                [serviceId, providerId]
        )
    }

    private void assertStaffOwner(Long staffId, Long providerId) {
        assertOwned(
                'SELECT id FROM staff WHERE id = ? AND provider_id = ?',
                [staffId, providerId]
        )
    }

    private void assertStaffBelongsToProvider(Long staffId, Long providerId) {
        assertStaffOwner(staffId, providerId)
    }

    private void assertScheduleOwner(Long scheduleId, Long providerId) {
        assertOwned(
                'SELECT ss.id FROM staff_schedules ss ' +
                        'JOIN staff s ON s.id = ss.staff_id ' +
                        'WHERE ss.id = ? AND s.provider_id = ?',
                [scheduleId, providerId]
        )
    }

    private void assertOwned(String query, List parameters) {
        if (sql.firstRow(query, parameters) == null) {
            throw new ApiException(403, 'You do not own this record or it does not exist')
        }
    }

    private Map requestBody() {
        try {
            String raw = request.reader.text?.trim()

            if (!raw) {
                return [:]
            }

            Object parsed = new JsonSlurper().parseText(raw)

            if (!(parsed instanceof Map)) {
                throw new ApiException(400, 'Request body must be a JSON object')
            }

            return parsed as Map
        } catch (ApiException exception) {
            throw exception
        } catch (Exception ignored) {
            throw new ApiException(400, 'Request body is not valid JSON')
        }
    }

    private String query(String name) {
        return request.getParameter(name)
    }

    private int integerQuery(String name, int defaultValue) {
        String value = query(name)

        if (!value) {
            return defaultValue
        }

        try {
            return Integer.parseInt(value)
        } catch (NumberFormatException ignored) {
            throw new ApiException(400, "${name} must be an integer")
        }
    }

    private Long asLong(Object value, String fieldName) {
        if (value == null || value.toString().trim().isEmpty()) {
            throw new ApiException(400, "${fieldName} is required")
        }

        try {
            return Long.parseLong(value.toString())
        } catch (NumberFormatException ignored) {
            throw new ApiException(400, "${fieldName} must be a number")
        }
    }
}
