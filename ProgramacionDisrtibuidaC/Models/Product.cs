using System.ComponentModel.DataAnnotations;

namespace ProgramacionDisrtibuidaC.Models
{
    public class Product
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "El nombre es obligatorio.")]
        [StringLength(
            200,
            MinimumLength = 2,
            ErrorMessage = "El nombre debe tener entre 2 y 200 letras.")]
        [RegularExpression(
            @"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+$",
            ErrorMessage = "El nombre solo puede contener letras, sin espacios.")]
        public string Name { get; set; } = string.Empty;

        [Range(
            typeof(decimal),
            "0.01",
            "99999999.99",
            ParseLimitsInInvariantCulture = true,
            ErrorMessage = "El precio debe estar entre 0,01 y 99999999,99.")]
        public decimal Price { get; set; }

        [Range(0, int.MaxValue, ErrorMessage = "El stock no puede ser negativo.")]
        public int Stock { get; set; }

        [Required(ErrorMessage = "La descripción es obligatoria.")]
        [StringLength(500, ErrorMessage = "La descripción no puede superar 500 caracteres.")]
        [RegularExpression(
            @"^[\s\S]*\S[\s\S]*$",
            ErrorMessage = "La descripción es obligatoria.")]
        public string Description { get; set; } = string.Empty;

        [Required(ErrorMessage = "La URL de la imagen es obligatoria.")]
        [StringLength(2048, ErrorMessage = "La URL no puede superar 2048 caracteres.")]
        [RegularExpression(
            @"^https?://[^/\s]+(?:/\S*)?$",
            ErrorMessage = "Ingrese una URL HTTP o HTTPS válida.")]
        public string ImageUrl { get; set; } = string.Empty;

        public bool IsActive { get; set; } = true;

        [Range(0, int.MaxValue, ErrorMessage = "La versión no puede ser negativa.")]
        public int Version { get; set; }
    }
}
