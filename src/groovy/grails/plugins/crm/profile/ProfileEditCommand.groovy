/*
 * Copyright 2012 Goran Ehrsson.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package grails.plugins.crm.profile

import grails.validation.Validateable

/**
 * Command object used when updating a user's public profile.
 */
@Validateable
class ProfileEditCommand implements Serializable {

    String username
    String name
    String email
    String password1
    String password2
    String address1
    String address2
    String address3
    String postalCode
    String city
    String region
    String countryCode
    String currency
    String telephone
    String mobile
    String url

    static constraints = {
        username(size: 3..80, maxSize: 80, nullable: false, blank: false, unique: true)
        name(size: 3..80, maxSize: 80, nullable: false, blank: false)
        email(maxSize: 80, blank: false, email: true)
        password1(size: 5..80, maxSize: 80, nullable: true, validator: {val, obj ->
            if (val && (val != obj.password2)) {
                return 'password.nomatch'
            }
            return null
        })
        password2(maxSize: 80, nullable: true)
        address1(maxSize: 80, nullable: true)
        address2(maxSize: 80, nullable: true)
        address3(maxSize: 80, nullable: true)
        postalCode(size: 2..20, maxSize: 20, nullable: true)
        city(size: 2..40, maxSize: 40, nullable: true)
        region(maxSize: 40, nullable: true)
        countryCode(size: 2..3, maxSize: 3, nullable: true)
        currency(maxSize: 4, nullable: true)
        telephone(size: 4..20, maxSize: 20, nullable: true)
        mobile(size: 4..20, maxSize: 20, nullable: true)
        url(maxSize: 255, nullable: true)
    }

    public static final List<String> PROPS = ["username", "name", "email", "address1", "address2", "address3", "postalCode", "city", "region", "countryCode", "currency", "telephone", "mobile", "url"]

    Map toMap() {
        def map = PROPS.inject([:]) {map, p ->
            def v = this[p]
            if (v) {
                map[p] = v
            }
            map
        }
        if (password1 && (password1 == password2)) {
            map.password = password1
        }
        return map
    }

    String toString() {
        username
    }
}
