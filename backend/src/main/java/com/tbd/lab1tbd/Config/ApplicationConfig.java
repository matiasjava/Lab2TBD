package com.tbd.lab1tbd.Config;

import com.tbd.lab1tbd.Repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
@RequiredArgsConstructor
public class ApplicationConfig {

    private static final Logger logger = LoggerFactory.getLogger(ApplicationConfig.class);
    private final UserRepository userRepository;

    /**
     * Define cómo Spring Security debe buscar a un usuario.
     */
    @Bean
    public UserDetailsService userDetailsService() {
        return username -> {
            logger.info("🔍 Buscando usuario: {}", username);

            return userRepository.getByEmail(username)
                    // Convertimos nuestro UserEntity a UserDetails de Spring Security
                    .map(user -> {
                        String hash = user.getPassword();
                        logger.info("Usuario encontrado - Email: {}", username);
                        logger.info("Hash longitud: {} caracteres", hash != null ? hash.length() : 0);
                        logger.info("Hash completo: {}", hash);

                        return new org.springframework.security.core.userdetails.User(
                                user.getEmail(),
                                hash, // Aquí va la contraseña hasheada
                                java.util.Collections.emptyList()
                        );
                    })
                    .orElseThrow(() -> {
                        logger.error("Usuario NO encontrado: {}", username);
                        return new UsernameNotFoundException("Usuario no encontrado con email: " + username);
                    });
        };
    }

    /**
     * Bean para el encriptador de contraseñas.
     * Usaremos BCrypt, el estándar de la industria.
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /**
     * El proveedor de autenticación.
     * Combina el 'UserDetailsService' (cómo buscar) y el 'PasswordEncoder' (cómo comparar contraseñas).
     */
    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService());
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    /**
     * El gestor de autenticación, necesario para el proceso de login.
     */
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }
}
