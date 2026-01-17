package com.tbd.lab2tbd.Entities;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserEntity {
    private Long id;
    private String name;
    private String email;
    private String password;
    private String biografia;
}