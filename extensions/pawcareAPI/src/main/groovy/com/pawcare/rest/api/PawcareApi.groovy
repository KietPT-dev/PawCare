package com.pawcare.rest.api

import groovy.json.JsonSlurper
import groovy.json.JsonOutput
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

        if (action == 'finance') {
            return handleFinance(method)
        }

        if (action == 'conversation-reports') {
            return handleConversationReports(method)
        }

        if (action == 'conversation-messages') {
            return handleReportedConversationMessages(method)
        }

        if (action == 'ai-risk-scores') {
            return handleAiRiskScores(method)
        }

        if (action == 'ai-risk-score') {
            return handleAiRiskScore(method)
        }

        if (action == 'ai-operational-recommendations') {
            return handleAiOperationalRecommendations(method)
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

        if (resource == 'providers') {
            return listRows(definition.table, "status = 'APPROVED' AND is_active = 1", [])
        }

        if (resource == 'services') {
            return listRows('services s JOIN providers p ON p.id = s.provider_id',
                    "s.is_active = 1 AND p.status = 'APPROVED' AND p.is_active = 1", [], 's.*', 's.id')
        }

        if (resource == 'categories') {
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
                        "p.owner_profile_id = ? AND p.status = 'APPROVED' AND p.is_active = 1",
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
                        "p.owner_profile_id = ? AND p.status = 'APPROVED' AND p.is_active = 1",
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
                // Approval fields are canonical backend state. Only the
                // authenticated ProviderApproval workflow callback may change them.
                body.remove('status')
                body.remove('is_active')
                body.remove('approval_decided_at')
                body.remove('approval_review_note')
                body.remove('rejection_reason')
                if (!isAdmin(profile)) {
                    assertProviderOwner(id, profile.id as Long)
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
                throw new ApiException(409,
                        'Provider status is controlled by the ProviderApproval workflow')

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

    /**
     * Back-office financial operations.  This stays in the Bonita extension so
     * the current Bonita session (and its ADMIN role) remains the authority for
     * every operation; no browser supplied profile id is trusted.
     */
    private Object handleFinance(String method) {
        Map profile = requireProfile(currentProfile(false))
        if (!isAdmin(profile)) throw new ApiException(403, 'Admin permission is required')

        switch (method) {
            case 'GET':
                return financeOverview(query('type'), query('status'), query('from'), query('to'))
            case 'PUT':
                return decideWithdrawal(profile, requestBody())
            case 'POST':
                return resolveDispute(profile, requestBody())
            default:
                throw new ApiException(405, "Method ${method} is not allowed for finance")
        }
    }

    /**
     * Bonita-session adapter for the Public API's intentionally narrow chat
     * moderation contract. It never lists arbitrary conversations and it never
     * returns message content unless the caller selected a reported conversation.
     */
    private Object handleConversationReports(String method) {
        Map profile = requireProfile(currentProfile(false))
        if (!isAdmin(profile)) throw new ApiException(403, 'Admin permission is required')

        switch (method) {
            case 'GET':
                return listConversationReports(query('status'), integerQuery('page', 0), integerQuery('size', 20))
            case 'PUT':
                return updateConversationReport(profile, requestBody())
            default:
                throw new ApiException(405, "Method ${method} is not allowed for conversation reports")
        }
    }

    private Object handleReportedConversationMessages(String method) {
        if (method != 'GET') throw new ApiException(405, "Method ${method} is not allowed for conversation messages")
        Map profile = requireProfile(currentProfile(false))
        if (!isAdmin(profile)) throw new ApiException(403, 'Admin permission is required')
        Long conversationId = asLong(query('conversation_id'), 'conversation_id')
        if (sql.firstRow('SELECT id FROM conversation_reports WHERE conversation_id = ?', [conversationId]) == null) {
            throw new ApiException(403, 'Conversation is not reported')
        }
        int size = Math.min(Math.max(integerQuery('size', 50), 1), 100)
        List rows = sql.rows('''
            SELECT m.id,m.conversation_id,m.sender_profile_id,m.content,m.recalled_at,
                   DATE_FORMAT(m.sent_at, '%d/%m/%Y %H:%i') AS sent_at,u.full_name AS sender_name
            FROM chat_messages m JOIN user_profiles u ON u.id = m.sender_profile_id
            WHERE m.conversation_id = ? ORDER BY m.id DESC LIMIT ?
        ''', [conversationId, size]).reverse()
        recordConversationAudit(profile.id as Long, 'CONVERSATION_REPORTED_VIEWED', 'CONVERSATION', conversationId,
                "messageCount=${rows.size()}")
        return [success: true, conversation_id: conversationId, messages: rows]
    }

    /** Bonita-session adapter for read-only AI scoring plus audited human review. */
    private Object handleAiRiskScores(String method) {
        Map profile = requireProfile(currentProfile(false))
        if (!isAdmin(profile)) throw new ApiException(403, 'Admin permission is required')
        switch (method) {
            case 'GET':
                return listAiRiskScores(query('riskLevel'), query('reviewStatus'), query('type'), integerQuery('page', 0), integerQuery('size', 20))
            case 'PUT':
                return reviewAiRiskScore(profile, requestBody())
            default:
                throw new ApiException(405, "Method ${method} is not allowed for AI risk scores")
        }
    }

    private Object handleAiRiskScore(String method) {
        if (method != 'GET') throw new ApiException(405, "Method ${method} is not allowed for AI risk score detail")
        Map profile = requireProfile(currentProfile(false))
        if (!isAdmin(profile)) throw new ApiException(403, 'Admin permission is required')
        Long id = asLong(query('id'), 'id')
        Map score = sql.firstRow('''SELECT s.id,s.aggregate_type,s.aggregate_id,s.model_name,s.model_version,s.risk_score,s.risk_level,
                   s.explanation_summary,s.feature_snapshot,s.scored_at,s.review_status,s.reviewer_profile_id,s.reviewed_at,s.reviewer_note,
                   reviewer.full_name AS reviewer_name
            FROM ai_risk_scores s LEFT JOIN user_profiles reviewer ON reviewer.id=s.reviewer_profile_id WHERE s.id=?''', [id])
        if (score == null) throw new ApiException(404, 'AI risk score not found')
        return score
    }

    private Map listAiRiskScores(String riskLevel, String reviewStatus, String type, int page, int size) {
        int safePage = Math.max(page, 0); int safeSize = Math.min(Math.max(size, 1), 100)
        List where = ['1=1']; List args = []
        if (riskLevel) { String level = riskLevel.toUpperCase(); if (!(level in ['LOW','MEDIUM','HIGH'])) throw new ApiException(400, 'Invalid riskLevel'); where << 's.risk_level=?'; args << level }
        if (reviewStatus) { String status = reviewStatus.toUpperCase(); if (!(status in ['OPEN','REVIEWED','DISMISSED'])) throw new ApiException(400, 'Invalid reviewStatus'); where << 's.review_status=?'; args << status }
        if (type) { where << 's.aggregate_type=?'; args << type.toUpperCase() }
        String clause = where.join(' AND ')
        Long total = sql.firstRow("SELECT COUNT(*) AS total FROM ai_risk_scores s WHERE ${clause}", args).total as Long
        List rows = sql.rows('''SELECT s.id,s.aggregate_type,s.aggregate_id,s.model_name,s.model_version,s.risk_score,s.risk_level,
                   s.explanation_summary,s.scored_at,s.review_status,s.reviewer_profile_id,s.reviewed_at,s.reviewer_note,
                   reviewer.full_name AS reviewer_name
            FROM ai_risk_scores s LEFT JOIN user_profiles reviewer ON reviewer.id=s.reviewer_profile_id
            WHERE ''' + clause + ' ORDER BY s.scored_at DESC,s.id DESC LIMIT ? OFFSET ?', args + [safeSize, safePage * safeSize])
        Map summary = sql.firstRow('''SELECT COUNT(*) AS total,
                 COALESCE(SUM(review_status='OPEN'),0) AS open_count,
                 COALESCE(SUM(risk_level='HIGH'),0) AS high_count,
                 COALESCE(SUM(review_status IN ('REVIEWED','DISMISSED')),0) AS reviewed_count
                 FROM ai_risk_scores''')
        return [items: rows, page: safePage, size: safeSize, totalElements: total ?: 0L,
                totalPages: total ? Math.ceil((total as double)/safeSize) as long : 0L, summary: summary]
    }

    private Map reviewAiRiskScore(Map profile, Map body) {
        Long id = asLong(body.id, 'id'); String status = requiredText(body.status, 'status').toUpperCase()
        if (!(status in ['OPEN','REVIEWED','DISMISSED'])) throw new ApiException(400, 'Invalid review status')
        String note = body.reviewerNote == null ? null : body.reviewerNote.toString().trim()
        if (note != null && note.length() > 1000) throw new ApiException(400, 'reviewerNote must not exceed 1000 characters')
        return sql.withTransaction {
            Map score = sql.firstRow('SELECT id,review_status FROM ai_risk_scores WHERE id=? FOR UPDATE', [id])
            if (score == null) throw new ApiException(404, 'AI risk score not found')
            if (status == 'OPEN') sql.executeUpdate('UPDATE ai_risk_scores SET review_status=?,reviewer_profile_id=NULL,reviewed_at=NULL,reviewer_note=? WHERE id=?', [status,note,id])
            else sql.executeUpdate('UPDATE ai_risk_scores SET review_status=?,reviewer_profile_id=?,reviewed_at=CURRENT_TIMESTAMP,reviewer_note=? WHERE id=?', [status,profile.id,note,id])
            recordConversationAudit(profile.id as Long, 'AI_RISK_REVIEW', 'AI_RISK_SCORE', id, "oldStatus=${score.review_status};newStatus=${status}")
            return [id:id,status:status,reviewer_note:note]
        }
    }

    private Object handleAiOperationalRecommendations(String method) {
        Map profile = requireProfile(currentProfile(false))
        if (!isAdmin(profile)) throw new ApiException(403, 'Admin permission is required')
        switch (method) {
            case 'GET':
                String status = query('status')?.toUpperCase()
                if (status && !(status in ['OPEN','REVIEWED','DISMISSED','APPROVED'])) throw new ApiException(400, 'Invalid status')
                String where = status ? 'WHERE r.status=?' : ''
                List args = status ? [status] : []
                return sql.rows('''SELECT r.id,r.recommendation_type,r.subject_name,r.model_name,r.model_version,r.score,r.confidence,r.payload,
                          r.status,r.created_at,r.reviewer_profile_id,r.reviewed_at,r.reviewer_note,reviewer.full_name AS reviewer_name
                   FROM ai_operational_recommendations r LEFT JOIN user_profiles reviewer ON reviewer.id=r.reviewer_profile_id ''' + where + ' ORDER BY r.created_at DESC,r.id DESC', args)
            case 'PUT':
                return reviewAiOperationalRecommendation(profile, requestBody())
            default:
                throw new ApiException(405, "Method ${method} is not allowed for AI operational recommendations")
        }
    }

    private Map reviewAiOperationalRecommendation(Map profile, Map body) {
        Long id = asLong(body.id, 'id'); String status = requiredText(body.status, 'status').toUpperCase()
        if (!(status in ['OPEN','REVIEWED','DISMISSED','APPROVED'])) throw new ApiException(400, 'Invalid review status')
        String note = body.reviewerNote == null ? null : body.reviewerNote.toString().trim()
        if (note != null && note.length() > 1000) throw new ApiException(400, 'reviewerNote must not exceed 1000 characters')
        return sql.withTransaction {
            Map recommendation = sql.firstRow('SELECT id,status FROM ai_operational_recommendations WHERE id=? FOR UPDATE', [id])
            if (recommendation == null) throw new ApiException(404, 'AI recommendation not found')
            sql.executeUpdate('UPDATE ai_operational_recommendations SET status=?,reviewer_profile_id=?,reviewed_at=CURRENT_TIMESTAMP,reviewer_note=? WHERE id=?', [status,profile.id,note,id])
            recordConversationAudit(profile.id as Long, 'AI_OPERATIONAL_RECOMMENDATION_REVIEW', 'AI_OPERATIONAL_RECOMMENDATION', id, "oldStatus=${recommendation.status};newStatus=${status}")
            return [id:id,status:status,reviewer_note:note]
        }
    }

    private Map listConversationReports(String status, int page, int size) {
        String selectedStatus = normalizeConversationReportStatus(status ?: 'OPEN')
        int safePage = Math.max(page, 0)
        int safeSize = Math.min(Math.max(size, 1), 100)
        Long total = sql.firstRow('SELECT COUNT(*) AS total FROM conversation_reports WHERE status = ?', [selectedStatus]).total as Long
        List content = sql.rows('''
            SELECT r.id AS report_id,r.conversation_id,r.category,r.note,r.status,
                   DATE_FORMAT(r.created_at, '%d/%m/%Y %H:%i') AS created_at,
                   DATE_FORMAT(r.reviewed_at, '%d/%m/%Y %H:%i') AS reviewed_at,
                   r.reviewer_note,c.booking_id,
                   reporter.id AS reporter_profile_id,reporter.full_name AS reporter_name,reporter.role_code AS reporter_role,
                   customer.id AS customer_profile_id,customer.full_name AS customer_name,
                   provider_profile.id AS provider_profile_id,
                   COALESCE(provider.name, provider_profile.full_name) AS provider_name,
                   reviewer.id AS reviewer_profile_id,reviewer.full_name AS reviewer_name
            FROM conversation_reports r
            JOIN conversations c ON c.id = r.conversation_id
            JOIN user_profiles reporter ON reporter.id = r.reporter_profile_id
            JOIN user_profiles customer ON customer.id = c.customer_profile_id
            JOIN user_profiles provider_profile ON provider_profile.id = c.provider_profile_id
            LEFT JOIN providers provider ON provider.owner_profile_id = c.provider_profile_id
            LEFT JOIN user_profiles reviewer ON reviewer.id = r.reviewed_by_profile_id
            WHERE r.status = ? ORDER BY r.created_at ASC,r.id ASC LIMIT ? OFFSET ?
        ''', [selectedStatus, safeSize, safePage * safeSize])
        return [success: true, content: content, page: safePage, size: safeSize,
                totalElements: total ?: 0L, totalPages: total ? Math.ceil((total as double) / safeSize) as long : 0L]
    }

    private Map updateConversationReport(Map profile, Map body) {
        Long reportId = asLong(body.report_id, 'report_id')
        String status = normalizeConversationReportStatus(requiredText(body.status, 'status'))
        String reviewerNote = body.reviewerNote == null ? null : body.reviewerNote.toString().trim()
        if (reviewerNote != null && reviewerNote.length() > 1000) throw new ApiException(400, 'reviewerNote must not exceed 1000 characters')
        return sql.withTransaction {
            Map report = sql.firstRow('SELECT id,conversation_id,status,reviewer_note FROM conversation_reports WHERE id = ? FOR UPDATE', [reportId])
            if (report == null) throw new ApiException(404, 'Conversation report not found')
            String oldStatus = report.status as String
            if (status == 'OPEN') {
                sql.executeUpdate('''UPDATE conversation_reports
                    SET status = 'OPEN', reviewed_by_profile_id = NULL, reviewed_at = NULL, reviewer_note = ? WHERE id = ?''', [reviewerNote, reportId])
            } else {
                sql.executeUpdate('''UPDATE conversation_reports
                    SET status = ?, reviewed_by_profile_id = ?, reviewed_at = CURRENT_TIMESTAMP, reviewer_note = ? WHERE id = ?''',
                        [status, profile.id, reviewerNote, reportId])
            }
            recordConversationAudit(profile.id as Long, 'CONVERSATION_REPORT_MODERATED', 'CONVERSATION_REPORT', reportId,
                    "conversationId=${report.conversation_id};oldStatus=${oldStatus};newStatus=${status}")
            return [success: true, report_id: reportId, conversation_id: report.conversation_id, status: status,
                    reviewer_note: reviewerNote]
        }
    }

    private String normalizeConversationReportStatus(String status) {
        String value = status?.trim()?.toUpperCase()
        if (!(value in ['OPEN', 'REVIEWED', 'DISMISSED'])) {
            throw new ApiException(400, 'status must be OPEN, REVIEWED, or DISMISSED')
        }
        return value
    }

    private void recordConversationAudit(Long profileId, String action, String entityType, Long entityId, String metadata) {
        try {
            sql.executeInsert('''INSERT INTO audit_logs (actor_profile_id,action_type,entity_type,entity_id,details_json)
                VALUES (?, ?, ?, ?, CAST(? AS JSON))''', [profileId, action, entityType, entityId,
                JsonOutput.toJson([event: metadata])])
        } catch (Exception ignored) {
            // Deployments predating audit_logs still enforce moderation; never log message bodies as a fallback.
        }
    }

    private Map financeOverview(String type, String withdrawalStatus, String from, String to) {
        List<String> types = ['DEPOSIT', 'ESCROW_HOLD', 'ESCROW_RELEASE', 'COMMISSION_FEE', 'PROVIDER_PAYOUT', 'WITHDRAWAL']
        if (type && !(type.toUpperCase() in types)) throw new ApiException(400, 'Unknown ledger transaction type')
        if (withdrawalStatus && !(withdrawalStatus.toUpperCase() in ['PENDING', 'APPROVED', 'REJECTED'])) {
            throw new ApiException(400, 'Unknown withdrawal status')
        }

        List bookingArgs = []
        String bookingRange = dateRange('b.created_at', from, to, bookingArgs)
        Map summary = sql.firstRow('''
            SELECT COALESCE(SUM(CASE WHEN b.status IN ('PENDING_APPROVAL','CONFIRMED','CHECKED_IN','IN_SERVICE','SERVICE_DONE','DISPUTED','COMPLETED') THEN b.estimated_price ELSE 0 END),0) AS gmv,
              COALESCE(SUM(b.status = 'DISPUTED'),0) AS disputed_bookings,
              COALESCE(SUM(b.status = 'SERVICE_DONE'),0) AS waiting_customer_confirmation
            FROM bookings b WHERE 1=1 ''' + bookingRange, bookingArgs)
        Map balances = sql.firstRow('''SELECT
              COALESCE((SELECT SUM(pd.amount) FROM payment_deposits pd WHERE pd.status = 'ESCROW_HELD'),0) AS escrow_held,
              COALESCE((SELECT SUM(available_balance + locked_balance) FROM wallets WHERE owner_type = 'USER'),0) AS user_wallets,
              COALESCE((SELECT SUM(available_balance + locked_balance) FROM wallets WHERE owner_type = 'PROVIDER'),0) AS provider_wallets,
              COALESCE((SELECT SUM(available_balance) FROM wallets WHERE owner_type = 'PLATFORM_ADMIN'),0) AS platform_wallets''')
        List transactionArgs = []
        String transactionRange = dateRange('t.created_at', from, to, transactionArgs)
        Map flows = sql.firstRow('''SELECT
              COALESCE(SUM(CASE WHEN t.type = 'COMMISSION_FEE' AND t.amount > 0 THEN t.amount ELSE 0 END),0) AS commission_revenue,
              COALESCE(SUM(CASE WHEN t.type = 'PROVIDER_PAYOUT' AND t.amount > 0 THEN t.amount ELSE 0 END),0) AS provider_payout
            FROM wallet_transactions t WHERE 1=1 ''' + transactionRange, transactionArgs)
        List withdrawalSummaryArgs = []
        String withdrawalRange = dateRange('wr.created_at', from, to, withdrawalSummaryArgs)
        Map withdrawalsSummary = sql.firstRow('''SELECT COALESCE(SUM(status = 'PENDING'),0) AS pending_count,
              COALESCE(SUM(CASE WHEN status = 'PENDING' THEN amount ELSE 0 END),0) AS pending_amount,
              COALESCE(SUM(CASE WHEN status = 'APPROVED' THEN amount ELSE 0 END),0) AS approved_amount
            FROM withdrawal_requests wr WHERE 1=1 ''' + withdrawalRange, withdrawalSummaryArgs)
        String ledgerWhere = 'WHERE 1=1' + (type ? ' AND t.type = ?' : '') + transactionRange
        List ledgerArgs = type ? [type.toUpperCase()] : []
        ledgerArgs.addAll(transactionArgs)
        List ledger = sql.rows('''
            SELECT DATE_FORMAT(t.created_at, '%d/%m/%Y %H:%i') AS created_at, t.id,t.booking_id,t.type,t.amount,t.balance_before,t.balance_after,t.description, w.owner_type, w.owner_id,
              COALESCE(up.full_name, pr.name, CASE WHEN w.owner_type = 'PLATFORM_ADMIN' THEN 'PawCare Platform' END) AS owner_name
            FROM wallet_transactions t
            JOIN wallets w ON w.id = t.wallet_id
            LEFT JOIN user_profiles up ON w.owner_type = 'USER' AND up.id = w.owner_id
            LEFT JOIN providers pr ON w.owner_type = 'PROVIDER' AND pr.id = w.owner_id
        ''' + ledgerWhere + ' ORDER BY t.created_at DESC, t.id DESC LIMIT 250', ledgerArgs)
        String withdrawalWhere = 'WHERE 1=1' + (withdrawalStatus ? ' AND wr.status = ?' : '') + withdrawalRange
        List withdrawalArgs = withdrawalStatus ? [withdrawalStatus.toUpperCase()] : []
        withdrawalArgs.addAll(withdrawalSummaryArgs)
        List withdrawals = sql.rows('''
            SELECT wr.id,wr.wallet_id,wr.amount,wr.bank_name,wr.bank_account_no,wr.bank_account_name,wr.bonita_case_id,wr.status,wr.admin_note,
              DATE_FORMAT(wr.created_at, '%d/%m/%Y %H:%i') AS created_at, DATE_FORMAT(wr.reviewed_at, '%d/%m/%Y %H:%i') AS reviewed_at,
              w.owner_type, w.owner_id,
              COALESCE(up.full_name, pr.name) AS owner_name,
              COALESCE(up.email, pr.email) AS owner_email
            FROM withdrawal_requests wr
            JOIN wallets w ON w.id = wr.wallet_id
            LEFT JOIN user_profiles up ON w.owner_type = 'USER' AND up.id = w.owner_id
            LEFT JOIN providers pr ON w.owner_type = 'PROVIDER' AND pr.id = w.owner_id
        ''' + withdrawalWhere + ' ORDER BY wr.created_at DESC, wr.id DESC LIMIT 250', withdrawalArgs)
        List disputes = sql.rows('''
            SELECT c.id AS complaint_id,c.status AS complaint_status,c.content,c.admin_response,DATE_FORMAT(c.created_at, '%d/%m/%Y %H:%i') AS created_at,
                   b.id AS booking_id,b.status AS booking_status,b.estimated_price,u.full_name AS customer_name,p.name AS provider_name,
                   COALESCE(pd.amount, 0) AS escrow_amount,pd.status AS escrow_status
            FROM complaints c
            JOIN user_profiles u ON u.id = c.customer_profile_id
            JOIN providers p ON p.id = c.provider_id
            JOIN bookings b ON b.id = c.booking_id
            LEFT JOIN payment_deposits pd ON pd.booking_id = b.id
            WHERE b.status = 'DISPUTED' OR c.status IN ('OPEN', 'IN_PROGRESS')
            ORDER BY c.created_at DESC, c.id DESC LIMIT 100
        ''')
        List histories = sql.rows('''SELECT h.booking_id,h.previous_status,h.new_status,h.note,DATE_FORMAT(h.changed_at, '%d/%m/%Y %H:%i') AS changed_at,
              u.full_name AS actor_name FROM booking_status_history h LEFT JOIN user_profiles u ON u.id=h.changed_by_profile_id
              WHERE h.booking_id IN (SELECT booking_id FROM complaints WHERE status IN ('OPEN','IN_PROGRESS')) ORDER BY h.changed_at DESC''')
        return [success: true, from: from ?: '', to: to ?: '', summary: summary + balances + flows + withdrawalsSummary,
                ledger: ledger, withdrawals: withdrawals, disputes: disputes, histories: histories,
                bookingStatuses: sql.rows('SELECT b.status,COUNT(*) AS booking_count,COALESCE(SUM(b.estimated_price),0) AS gross_amount FROM bookings b WHERE 1=1 ' + bookingRange + ' GROUP BY b.status ORDER BY b.status', bookingArgs)]
    }

    private Map decideWithdrawal(Map profile, Map body) {
        Long id = asLong(body.id, 'id')
        String decision = requiredText(body.decision, 'decision').toUpperCase()
        if (!(decision in ['APPROVED', 'REJECTED'])) throw new ApiException(400, 'decision must be APPROVED or REJECTED')
        String note = body.admin_note?.toString()?.trim()
        return sql.withTransaction {
            Map wr = sql.firstRow('SELECT * FROM withdrawal_requests WHERE id = ? FOR UPDATE', [id])
            if (wr == null) throw new ApiException(404, 'Withdrawal request not found')
            if (wr.status != 'PENDING') throw new ApiException(409, 'Withdrawal request has already been decided')
            Map wallet = sql.firstRow('SELECT * FROM wallets WHERE id = ? FOR UPDATE', [wr.wallet_id])
            BigDecimal amount = wr.amount as BigDecimal
            BigDecimal available = wallet.available_balance as BigDecimal
            BigDecimal locked = wallet.locked_balance as BigDecimal
            if (locked < amount) throw new ApiException(409, 'Reserved withdrawal balance is inconsistent')
            if (decision == 'APPROVED') {
                sql.executeUpdate('UPDATE wallets SET locked_balance = locked_balance - ? WHERE id = ?', [amount, wallet.id])
                sql.executeInsert('''INSERT INTO wallet_transactions
                    (wallet_id, booking_id, type, amount, balance_before, balance_after, description)
                    VALUES (?, NULL, 'WITHDRAWAL', ?, ?, ?, ?)''',
                    [wallet.id, amount.negate(), locked, locked - amount, "Withdrawal approved and paid out, request #${id}"])
            } else {
                sql.executeUpdate('UPDATE wallets SET available_balance = available_balance + ?, locked_balance = locked_balance - ? WHERE id = ?', [amount, amount, wallet.id])
                sql.executeInsert('''INSERT INTO wallet_transactions
                    (wallet_id, booking_id, type, amount, balance_before, balance_after, description)
                    VALUES (?, NULL, 'WITHDRAWAL', ?, ?, ?, ?)''',
                    [wallet.id, amount, available, available + amount, "Withdrawal rejected; amount returned, request #${id}"])
            }
            sql.executeUpdate('''UPDATE withdrawal_requests
                SET status = ?, admin_note = ?, reviewed_by_profile_id = ?, reviewed_at = CURRENT_TIMESTAMP
                WHERE id = ?''', [decision, note, profile.id, id])
            [success: true, id: id, status: decision]
        }
    }

    private Map resolveDispute(Map profile, Map body) {
        Long complaintId = asLong(body.complaint_id, 'complaint_id')
        String action = requiredText(body.action ?: 'REFUND_TO_CUSTOMER', 'action').toUpperCase()
        if (!(action in ['REFUND_TO_CUSTOMER', 'RELEASE_TO_PROVIDER'])) {
            throw new ApiException(400, 'action must be REFUND_TO_CUSTOMER or RELEASE_TO_PROVIDER')
        }
        String note = body.admin_note?.toString()?.trim() ?: 'Force refund approved by admin'
        return sql.withTransaction {
            Map complaint = sql.firstRow('SELECT * FROM complaints WHERE id = ? FOR UPDATE', [complaintId])
            if (complaint == null) throw new ApiException(404, 'Complaint not found')
            Map booking = sql.firstRow("SELECT * FROM bookings WHERE id = ? FOR UPDATE", [complaint.booking_id])
            if (booking == null) throw new ApiException(404, 'Booking not found')
            if (booking.status != 'DISPUTED') throw new ApiException(409, 'Only a DISPUTED booking can be resolved')
            Map deposit = sql.firstRow("SELECT * FROM payment_deposits WHERE booking_id = ? AND status = 'ESCROW_HELD' FOR UPDATE", [complaint.booking_id])
            if (deposit == null) throw new ApiException(409, 'This dispute has no escrow currently held')
            Map wallet = sql.firstRow("SELECT * FROM wallets WHERE owner_type = 'USER' AND owner_id = ? FOR UPDATE", [complaint.customer_profile_id])
            if (wallet == null) throw new ApiException(409, 'Customer wallet not found')
            BigDecimal amount = deposit.amount as BigDecimal
            BigDecimal locked = wallet.locked_balance as BigDecimal
            BigDecimal available = wallet.available_balance as BigDecimal
            if (locked < amount) throw new ApiException(409, 'Escrow balance is inconsistent')
            if (action == 'REFUND_TO_CUSTOMER') {
                sql.executeUpdate('UPDATE wallets SET available_balance = available_balance + ?, locked_balance = locked_balance - ? WHERE id = ?', [amount, amount, wallet.id])
                sql.executeInsert('''INSERT INTO wallet_transactions
                    (wallet_id, booking_id, type, amount, balance_before, balance_after, description)
                    VALUES (?, ?, 'ESCROW_RELEASE', ?, ?, ?, ?)''',
                    [wallet.id, complaint.booking_id, amount, available, available + amount, "Admin dispute refund #${complaintId}: ${note}"])
                sql.executeUpdate("UPDATE bookings SET status = 'CANCELLED', cancel_reason = ? WHERE id = ?", ['Admin dispute refund', booking.id])
            } else {
                Map provider = sql.firstRow("SELECT * FROM wallets WHERE owner_type = 'PROVIDER' AND owner_id = ? FOR UPDATE", [booking.provider_id])
                if (provider == null) throw new ApiException(409, 'Provider wallet not found')
                Map platform = sql.firstRow("SELECT * FROM wallets WHERE owner_type = 'PLATFORM_ADMIN' AND owner_id = 0 FOR UPDATE")
                if (platform == null) throw new ApiException(409, 'Platform wallet not found')
                BigDecimal fee = amount.multiply(new BigDecimal('0.10')).setScale(2, java.math.RoundingMode.HALF_UP)
                BigDecimal payout = amount.subtract(fee)
                BigDecimal providerAvailable = provider.available_balance as BigDecimal
                BigDecimal platformAvailable = platform.available_balance as BigDecimal
                sql.executeUpdate('UPDATE wallets SET locked_balance = locked_balance - ? WHERE id = ?', [amount, wallet.id])
                sql.executeInsert("INSERT INTO wallet_transactions (wallet_id,booking_id,type,amount,balance_before,balance_after,description) VALUES (?,?, 'ESCROW_RELEASE', ?,?,?,?)", [wallet.id, booking.id, amount.negate(), locked, locked - amount, "Escrow settled after dispute #${complaintId}"])
                sql.executeUpdate('UPDATE wallets SET available_balance = available_balance + ? WHERE id = ?', [payout, provider.id])
                sql.executeInsert("INSERT INTO wallet_transactions (wallet_id,booking_id,type,amount,balance_before,balance_after,description) VALUES (?,?, 'PROVIDER_PAYOUT', ?,?,?,?)", [provider.id, booking.id, payout, providerAvailable, providerAvailable + payout, "Provider payout after dispute #${complaintId}"])
                sql.executeUpdate('UPDATE wallets SET available_balance = available_balance + ? WHERE id = ?', [fee, platform.id])
                sql.executeInsert("INSERT INTO wallet_transactions (wallet_id,booking_id,type,amount,balance_before,balance_after,description) VALUES (?,?, 'COMMISSION_FEE', ?,?,?,?)", [platform.id, booking.id, fee, platformAvailable, platformAvailable + fee, "Platform commission after dispute #${complaintId}"])
                sql.executeUpdate("UPDATE bookings SET status = 'COMPLETED' WHERE id = ?", [booking.id])
            }
            sql.executeUpdate("UPDATE payment_deposits SET status = 'EXPIRED' WHERE id = ?", [deposit.id])
            sql.executeUpdate("UPDATE complaints SET status = 'RESOLVED', admin_response = ?, resolved_at = CURRENT_TIMESTAMP WHERE id = ?", [note, complaintId])
            String finalStatus = action == 'REFUND_TO_CUSTOMER' ? 'CANCELLED' : 'COMPLETED'
            addBookingHistory(booking.id as Long, 'DISPUTED', finalStatus, profile.id as Long, note)
            notifyProfile(complaint.customer_profile_id as Long, 'Tranh chấp đã xử lý', action == 'REFUND_TO_CUSTOMER' ? "Escrow Booking #${booking.id} đã hoàn về ví." : "Escrow Booking #${booking.id} đã giải ngân cho Provider.", 'COMPLAINT', 'COMPLAINT', complaintId)
            [success: true, complaint_id: complaintId, booking_id: booking.id, status: finalStatus, action: action, amount: amount]
        }
    }

    private String dateRange(String column, String from, String to, List args) {
        if (from && !(from ==~ /\\d{4}-\\d{2}-\\d{2}/)) throw new ApiException(400, 'from must use yyyy-MM-dd')
        if (to && !(to ==~ /\\d{4}-\\d{2}-\\d{2}/)) throw new ApiException(400, 'to must use yyyy-MM-dd')
        if (from && to && from > to) throw new ApiException(400, 'from cannot be after to')
        String result = ''
        if (from) { result += " AND ${column} >= ?"; args << from + ' 00:00:00' }
        if (to) { result += " AND ${column} < DATE_ADD(?, INTERVAL 1 DAY)"; args << to + ' 00:00:00' }
        return result
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

        /*
         * Development organizations are imported by Bonita with runtime-generated
         * user IDs.  The original PawCare seed used fixed IDs (10001..10003), so
         * a real Bonita Administrator could otherwise be rejected before the API
         * reached its role check.  The Bonita session profile is authoritative for
         * this compatibility path; a regular customer can never reach it.
         *
         * Keep the returned PawCare profile for audit/reviewer foreign keys.  The
         * legacy row is deliberately limited to the seeded ADMIN identity rather
         * than selecting an arbitrary administrator profile.
         */
        if (profile == null && hasBonitaAdministratorProfile()) {
            profile = sql.firstRow(
                    "SELECT * FROM user_profiles WHERE bonita_user_id = 10003 AND role_code = 'ADMIN' AND is_active = 1"
            )
        }

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

    private boolean hasBonitaAdministratorProfile() {
        return (context.apiSession.profiles ?: []).contains('Administrator')
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
                "SELECT id FROM providers WHERE owner_profile_id = ? AND status = 'APPROVED' AND is_active = 1",
                [profile.id]
        )

        if (provider == null) {
            throw new ApiException(403, 'Provider approval is required before this business action')
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
