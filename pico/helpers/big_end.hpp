#pragma once

#include <stdint.h>

class be_uint16_t {
public:
    be_uint16_t() : be_val_(0) {}

    be_uint16_t(const uint16_t &val)
        : be_val_(static_cast<uint16_t>(
            (val >> 8) |
            (val << 8)))
    {}

    operator uint16_t() const {
        return static_cast<uint16_t>(
            (be_val_ >> 8) |
            (be_val_ << 8));
    }

private:
    uint16_t be_val_;
} __attribute__((packed));


class be_uint32_t {
public:
    be_uint32_t() : be_val_(0) {}

    be_uint32_t(const uint32_t &val)
        : be_val_(
            ((val >> 24) & 0x000000FFu) |
            ((val >> 8)  & 0x0000FF00u) |
            ((val << 8)  & 0x00FF0000u) |
            ((val << 24) & 0xFF000000u))
    {}

    operator uint32_t() const {
        return
            ((be_val_ >> 24) & 0x000000FFu) |
            ((be_val_ >> 8)  & 0x0000FF00u) |
            ((be_val_ << 8)  & 0x00FF0000u) |
            ((be_val_ << 24) & 0xFF000000u);
    }

private:
    uint32_t be_val_;
} __attribute__((packed));


class be_uint64_t {
public:
    be_uint64_t() : be_val_(0) {}

    be_uint64_t(const uint64_t &val)
        : be_val_(
            ((val >> 56) & 0x00000000000000FFULL) |
            ((val >> 40) & 0x000000000000FF00ULL) |
            ((val >> 24) & 0x0000000000FF0000ULL) |
            ((val >> 8)  & 0x00000000FF000000ULL) |
            ((val << 8)  & 0x000000FF00000000ULL) |
            ((val << 24) & 0x0000FF0000000000ULL) |
            ((val << 40) & 0x00FF000000000000ULL) |
            ((val << 56) & 0xFF00000000000000ULL))
    {}

    operator uint64_t() const {
        return
            ((be_val_ >> 56) & 0x00000000000000FFULL) |
            ((be_val_ >> 40) & 0x000000000000FF00ULL) |
            ((be_val_ >> 24) & 0x0000000000FF0000ULL) |
            ((be_val_ >> 8)  & 0x00000000FF000000ULL) |
            ((be_val_ << 8)  & 0x000000FF00000000ULL) |
            ((be_val_ << 24) & 0x0000FF0000000000ULL) |
            ((be_val_ << 40) & 0x00FF000000000000ULL) |
            ((be_val_ << 56) & 0xFF00000000000000ULL);
    }

private:
    uint64_t be_val_;
} __attribute__((packed));